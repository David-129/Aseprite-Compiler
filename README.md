# Aseprite-One-Click-Builder-for-Windows
Build stable Aseprite + installer in one clean, automated batch script.

## 📦 Aseprite Auto Build Script

This script helps you automatically download, configure, compile, and package the latest **stable version** of [Aseprite](https://www.aseprite.org) on Windows using Visual Studio, CMake, Ninja, and Inno Setup.

> ⚠️ This script does **NOT crack** or bypass Aseprite’s licensing. It only builds from the open-source code provided by Aseprite's GitHub under their terms.  
> Please **buy a license** if you use Aseprite regularly: https://aseprite.org

---

## ✅ Features

- Automatically fetches the latest stable Aseprite source code
- Downloads and extracts the correct Skia binary
- Fully cleans old builds
- Builds with Visual Studio + Ninja
- Creates a Windows installer via Inno Setup
- Ensures version number is correct in final binary

---

## 🧰 Requirements

You must have the following installed and configured:

| Tool         | Notes |
|--------------|-------|
| **Visual Studio 2019 or 2022** | Must include **C++ Desktop Development** and `vcvars64.bat` |
| **CMake**     | Add to PATH. https://cmake.org/ |
| **Ninja**     | Add to PATH. https://ninja-build.org/ |
| **PowerShell** | Comes with Windows |
| **Inno Setup** | Add `ISCC.exe` to PATH. https://jrsoftware.org/isinfo.php |

---

## 📂 Folder Structure

By default, the script assumes this structure:

```
D:\Project\aseprite_builder\
│
├── build\              ← build output
├── installer\          ← final installer
├── skia\               ← extracted Skia
├── aseprite\           ← extracted Aseprite source
├── aseprite.zip        ← downloaded source
├── Skia-Windows-Release-x64.zip
├── aseprite_installer.iss
├── build_aseprite.bat  ← this script
```

You can edit `ROOT_DIR` inside the script if needed.

---

## 🚀 How to Use

1. **Download the script** `build_aseprite.bat`.
2. Place it in your desired folder (e.g., `D:\Project\aseprite_builder`).
3. **Run the script by double-clicking** it or via command line.
4. Wait ~5–10 minutes. If successful, the final `.exe` installer will be inside the `installer` folder.

---

## 📄 License

This script is licensed under a [custom MIT-style license](./LICENSE) with added ethical restrictions.

- ✅ You may use and modify this script for **personal and educational purposes**.
- ❌ You may **not** use it to build or distribute **Aseprite binaries (.exe, installers, etc.)** without a valid license from the official developers.

This project is **not affiliated with or endorsed by Aseprite**.  
Please support the original developers: https://www.aseprite.org
