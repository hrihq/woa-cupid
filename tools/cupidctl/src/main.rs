use std::fs;
use std::path::{Path, PathBuf};
use std::process::ExitCode;

fn parse_args(args: &[String]) -> Result<(String, PathBuf), String> {
    let mut command = None;
    let mut root = PathBuf::from(".");
    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "--root" => {
                i += 1;
                if i >= args.len() {
                    return Err("--root needs a path".into());
                }
                root = PathBuf::from(&args[i]);
            }
            s if s.starts_with('-') => return Err(format!("unknown flag: {s}")),
            s => {
                if command.is_some() {
                    return Err("only one command".into());
                }
                command = Some(s.to_string());
            }
        }
        i += 1;
    }
    command
        .map(|c| (c, root))
        .ok_or_else(|| "command required".into())
}

fn manifest_ok(text: &str) -> bool {
    text.contains("\"drivers\"")
        && text.contains("\"source\"")
        && text.contains("\"target\"")
        && text.matches("\"id\"").count() >= 4
}

fn verify_platform(root: &Path) -> Result<usize, String> {
    let required = [
        "firmware/cupid_bootshim.S",
        "firmware/acpi/DSDT.asl",
        "firmware/acpi/SSDT-CPU.asl",
        "firmware/acpi/SSDT-USB.asl",
        "firmware/acpi/SSDT-STORAGE.asl",
        "firmware/acpi/SSDT-DISPLAY.asl",
        "firmware/config/cupid.toml",
        ".github/workflows/ci.yml",
    ];
    let mut checks = 0;
    for rel in required {
        if !root.join(rel).is_file() {
            return Err(format!("missing {rel}"));
        }
        checks += 1;
    }
    let config = fs::read_to_string(root.join("firmware/config/cupid.toml"))
        .map_err(|e| format!("config: {e}"))?;
    for token in [
        "requires_kernel_header = true",
        "base = 0xA7100000",
        "size = 0x300000",
    ] {
        if !config.contains(token) {
            return Err(format!("config missing: {token}"));
        }
        checks += 1;
    }
    let shim = fs::read_to_string(root.join("firmware/cupid_bootshim.S"))
        .map_err(|e| format!("BootShim: {e}"))?;
    for token in ["_Start", "REQUIRES_KERNEL_HEADER", "FD_BASE"] {
        if !shim.contains(token) {
            return Err(format!("BootShim missing: {token}"));
        }
        checks += 1;
    }
    Ok(checks)
}

fn verify_drivers(root: &Path) -> Result<usize, String> {
    let manifest = fs::read_to_string(root.join("drivers/manifest.json"))
        .map_err(|e| format!("manifest: {e}"))?;
    if !manifest_ok(&manifest) {
        return Err("manifest schema invalid".into());
    }
    let mut stack = vec![root.join("drivers")];
    let mut binaries = Vec::new();
    while let Some(dir) = stack.pop() {
        for entry in fs::read_dir(&dir).map_err(|e| format!("read_dir: {e}"))? {
            let path = entry.map_err(|e| format!("entry: {e}"))?.path();
            if path.is_dir() {
                if path.file_name().is_some_and(|n| n == "cache") {
                    continue;
                }
                stack.push(path);
            } else if matches!(
                path.extension().and_then(|s| s.to_str()),
                Some("sys" | "inf" | "cab" | "efi" | "dll")
            ) {
                binaries.push(path.display().to_string());
            }
        }
    }
    if !binaries.is_empty() {
        return Err(format!("driver binaries must not be tracked: {}", binaries.join(", ")));
    }
    Ok(manifest.matches("\"id\"").count())
}

fn usage() {
    println!("cupidctl 0.1 (placeholder)");
    println!("  verify-platform --root <dir>   check firmware/config/ACPI/CI files");
    println!("  verify-drivers  --root <dir>   check driver manifest, no tracked blobs");
    println!("  flash-image     --image <img>  NOT IMPLEMENTED (M3)");
    println!("  apply-acpi      --aml <file>   NOT IMPLEMENTED (M3)");
}

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();
    if args.iter().any(|a| a == "--help" || a == "-h") {
        usage();
        return ExitCode::SUCCESS;
    }
    let (command, root) = match parse_args(&args) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("cupidctl: {e}");
            usage();
            return ExitCode::from(2);
        }
    };
    let result = match command.as_str() {
        "verify-platform" => verify_platform(&root).map(|n| format!("verify-platform: PASS ({n} checks)")),
        "verify-drivers" => verify_drivers(&root).map(|n| format!("verify-drivers: PASS ({n} entries)")),
        "flash-image" | "apply-acpi" => {
            eprintln!("cupidctl {command}: NOT IMPLEMENTED (M3)");
            return ExitCode::from(2);
        }
        other => Err(format!("unknown command: {other}")),
    };
    match result {
        Ok(line) => {
            println!("{line}");
            ExitCode::SUCCESS
        }
        Err(e) => {
            eprintln!("cupidctl: FAIL: {e}");
            ExitCode::FAILURE
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_root_flag() {
        let args = ["verify-platform", "--root", "."]
            .map(String::from);
        let (cmd, root) = parse_args(&args).unwrap();
        assert_eq!(cmd, "verify-platform");
        assert_eq!(root.as_path(), Path::new("."));
    }

    #[test]
    fn rejects_bad_manifest() {
        assert!(!manifest_ok("{}"));
        assert!(manifest_ok("{\"drivers\":[{\"id\":\"a\",\"source\":\"s\",\"target\":\"t\"},{\"id\":\"b\"},{\"id\":\"c\"},{\"id\":\"d\"}]}"));
    }
}
