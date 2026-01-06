**Mafia: The City of Lost Heaven — Cutscene Tools**

This repository contains a set of tools for creating and editing cutscenes in the classic game *Mafia: The City of Lost Heaven*. The tools were developed to support modders and enthusiasts in working with the game's binary cutscene formats (`.rep` and `.chg`).

**Main tools included:**
- **RepEditor** — editor for `.rep`.
- **ChgEditor** — editor for `.chg`.
- **3ds Max plugins** — scripts for exporting cameras, target points, and character/car frames to `.rep` format.

**Requirements:**
- .NET Framework 4.8 (required for RepEditor and ChgEditor).
- 3ds Max (for using the provided MAXScript plugins).

**Project details:**
- RepEditor and ChgEditor are written in C# (.NET Framework 4.8).
- 3ds Max plugins are written in MAXScript.
- The repository includes a full installation guide (`Install_Guide.txt`) and documentation in both Russian and English.

* **Always back up original `.rep` and `.chg` files before editing.**
* Some `.chg` files may contain non-standard `ScriptsBlock` variants; `ChgEditor` can skip or mishandle such blocks. See `README.md` for warnings and examples — avoid saving files that trigger this behavior to prevent corruption or crashes.
* The author is not responsible for damage to game files; use the tools at your own risk.

## Contributing

Contributions, bug reports and documentation improvements are welcome — please open an issue or a pull request on GitHub.

---

If you want, I can also produce a short repository description (the single-line blurb shown on GitHub) and a `README.md` template using this text. Which would you prefer?

