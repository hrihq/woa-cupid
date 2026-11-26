use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::{Path, PathBuf};
use std::process::ExitCode;

struct Args {
    command: String,
    root: PathBuf,
    options: HashMap<String, String>,
    flags: HashSet<String>,
}

fn parse_args(args: &[String]) -> Result<Args, String> {
    let mut command = None;
    let mut root = PathBuf::from(".");
    let mut options = HashMap::new();
    let mut flags = HashSet::new();
    let value_flags = ["--root", "--image", "--device", "--slot", "--aml"];
    let bool_flags = ["--dry-run", "--execute"];
    let mut i = 0;
    while i < args.len() {
        let token = args[i].as_str();
        if value_flags.contains(&token) {
            i += 1;
            if i >= args.len() {
                return Err(format!("{token} needs a value"));
            }
            let value = args[i].clone();
            if token == "--root" {
                root = PathBuf::from(&value);
            }
            options.insert(token.trim_start_matches("--").to_string(), value);
        } else if bool_flags.contains(&token) {
            flags.insert(token.trim_start_matches("--").to_string());
        } else if token.starts_with('-') {
            return Err(format!("unknown flag: {token}"));
        } else if command.is_none() {
            command = Some(token.to_string());
        } else {
            return Err("only one command".into());
        }
        i += 1;
    }
    let command = command.ok_or_else(|| "command required".to_string())?;
    Ok(Args { command, root, options, flags })
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

fn acpi_checksum_ok(bytes: &[u8]) -> bool {
    bytes.len() >= 36 && bytes.iter().fold(0u8, |acc, b| acc.wrapping_add(*b)) == 0
}

fn acpi_signature(bytes: &[u8]) -> Option<&str> {
    let sig = std::str::from_utf8(bytes.get(0..4)?).ok()?;
    (sig.bytes().all(|b| b.is_ascii_alphanumeric())).then_some(sig)
}

fn flash_image(args: &Args) -> Result<String, String> {
    let image = args.options.get("image").ok_or("--image required")?;
    let meta = fs::metadata(image).map_err(|e| format!("image: {e}"))?;
    if meta.len() < 512 {
        return Err("image too small (<512 bytes)".into());
    }
    let slot = args.options.get("slot").map(String::as_str).unwrap_or("a");
    if !matches!(slot, "a" | "b") {
        return Err("--slot must be a or b".into());
    }
    if args.flags.contains("execute") {
        return Err("flashing disabled; use your own fastboot/EDL flow (docs/INSTALL_WINDOWS.md)".into());
    }
    Ok(format!(
        "flash-image: DRY-RUN slot={slot} image={image} bytes={} plan=fastboot flash boot_{slot} {image}",
        meta.len()
    ))
}

fn apply_acpi(args: &Args) -> Result<String, String> {
    let aml = args.options.get("aml").ok_or("--aml required")?;
    let bytes = fs::read(aml).map_err(|e| format!("aml: {e}"))?;
    let sig = acpi_signature(&bytes).ok_or("invalid ACPI signature")?;
    let declared = u32::from_le_bytes([bytes[4], bytes[5], bytes[6], bytes[7]]) as usize;
    if declared != bytes.len() {
        return Err(format!("ACPI length mismatch: header {declared}, file {}", bytes.len()));
    }
    if !acpi_checksum_ok(&bytes) {
        return Err("ACPI checksum failed".into());
    }
    if args.flags.contains("execute") {
        return Err("apply-acpi disabled; stage AML in firmware/out/acpi yourself".into());
    }
    Ok(format!(
        "apply-acpi: DRY-RUN table={sig} len={} checksum=OK plan=firmware/out/acpi/{sig}.aml",
        bytes.len()
    ))
}

fn usage() {
    println!("cupidctl 0.2 (M3 dry-run tooling)");
    println!("  verify-platform --root <dir>   check firmware/config/ACPI/CI files");
    println!("  verify-drivers  --root <dir>   check driver manifest, no tracked blobs");
    println!("  flash-image --image <img> [--slot a|b]     validate + print flash plan");
    println!("  apply-acpi  --aml <file>                    validate AML + print staging plan");
    println!("  --execute is refused; no partition is written");
}

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();
    if args.iter().any(|a| a == "--help" || a == "-h") {
        usage();
        return ExitCode::SUCCESS;
    }
    let args = match parse_args(&args) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("cupidctl: {e}");
            usage();
            return ExitCode::from(2);
        }
    };
    let result = match args.command.as_str() {
        "verify-platform" => {
            verify_platform(&args.root).map(|n| format!("verify-platform: PASS ({n} checks)"))
        }
        "verify-drivers" => {
            verify_drivers(&args.root).map(|n| format!("verify-drivers: PASS ({n} entries)"))
        }
        "flash-image" => flash_image(&args),
        "apply-acpi" => apply_acpi(&args),
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
        let args = ["verify-platform", "--root", "."].map(String::from);
        let parsed = parse_args(&args).unwrap();
        assert_eq!(parsed.command, "verify-platform");
        assert_eq!(parsed.root.as_path(), Path::new("."));
    }

    #[test]
    fn parses_command_options() {
        let args = ["flash-image", "--image", "boot.img", "--slot", "b", "--dry-run"]
            .map(String::from);
        let parsed = parse_args(&args).unwrap();
        assert_eq!(parsed.options.get("image").unwrap(), "boot.img");
        assert_eq!(parsed.options.get("slot").unwrap(), "b");
        assert!(parsed.flags.contains("dry-run"));
    }

    #[test]
    fn rejects_bad_manifest() {
        assert!(!manifest_ok("{}"));
        assert!(manifest_ok("{\"drivers\":[{\"id\":\"a\",\"source\":\"s\",\"target\":\"t\"},{\"id\":\"b\"},{\"id\":\"c\"},{\"id\":\"d\"}]}"));
    }

    #[test]
    fn validates_acpi_checksum() {
        let mut table = vec![0u8; 36];
        table[0..4].copy_from_slice(b"DSDT");
        table[4..8].copy_from_slice(&36u32.to_le_bytes());
        let sum = table.iter().fold(0u8, |acc, b| acc.wrapping_add(*b));
        table[9] = 0u8.wrapping_sub(sum);
        assert_eq!(acpi_signature(&table), Some("DSDT"));
        assert!(acpi_checksum_ok(&table));
        table[20] = 1;
        assert!(!acpi_checksum_ok(&table));
    }
}
