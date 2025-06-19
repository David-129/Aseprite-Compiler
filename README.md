# Aseprite-Compiler
Build stable Aseprite + installer in one clean, automated batch script.

> ⚠️ **Legal Notice**: By downloading or using this script, you agree to the terms of the included [custom license](LICENSE).  
> This script is provided **only for personal and educational purposes**. It does **not** grant you any rights to the Aseprite software itself.  
> Do **not** use this script to distribute or share compiled Aseprite builds unless you have a valid commercial license from https://aseprite.org.

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
├── Aseprite_Builder.bat  ← this script
```

You can edit `ROOT_DIR` inside the script if needed.

---

## 🔧 Customizing Build Location

By default, the script uses a fixed root path like:

```bat
set ROOT_DIR=D:\Project\aseprite_builder
```

You can easily change this to any other directory.  
For example, to use drive E instead:

```bat
set ROOT_DIR=E:\Tools\MyAsepriteBuild
```

---

### 🧳 Make It Portable (Optional)

To make the script use the folder it's located in (no manual path edits), replace that line with:

```bat
set ROOT_DIR=%~dp0
```

This makes it **portable** — you can move the script anywhere, and it will always build in the same folder it's in.

> 💡 `%~dp0` means "directory path of the current `.bat` script".

---

### 🧭 Configure Visual Studio Path (Required)

Before using the script, you must configure the correct path to Visual Studio's `vcvars64.bat`, which sets up the C++ build environment.

Open `build_aseprite.bat`, and look for this line:

```bat
CALL "D:\vst_tools\VC\Auxiliary\Build\vcvars64.bat"
```

Replace it with the correct path to your installed Visual Studio.  
A common default path for Visual Studio 2022 (Community edition) is:

```bat
CALL "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
```

#### ✅ How to find `vcvars64.bat`

1. Open **File Explorer**
2. Go to: `C:\Program Files\Microsoft Visual Studio\`
3. Use the search bar to look for `vcvars64.bat`
4. Right-click → **Copy full path**
5. Paste it in the script as shown above

> ⚠️ If this file is not set correctly, the build will **fail**. This step is mandatory.

---

## 🚀 How to Use Aseprite_Builder.bat

1. **Download the script** `build_aseprite.bat`.
2. Place it in your desired folder (e.g., `D:\Project\aseprite_builder`).
3. **Run the script by double-clicking** it or via command line.
4. Wait ~5–10 minutes. If successful, the final `.exe` installer will be inside the `installer` folder.

---

## 📄 License

This script is licensed under a [custom MIT-style license](LICENSE) with added ethical restrictions.

- ✅ You may use and modify this script for **personal and educational purposes**.
- ❌ You may **not** use it to build or distribute **Aseprite binaries (.exe, installers, etc.)** without a valid license from the official developers.

This project is **not affiliated with or endorsed by Aseprite**.  
Please support the original developers: https://www.aseprite.org
