# FL Studio Plugin Sorter

[Get straight into it!](#get-started)

Sorts your FL Studio plugin menus with PowerShell. Sort by vendor and function or manually categorize them in CSV.

## The Problem
FL Studio has a feature called "flag as favorite" which is convenient to quickly add a new plugin to menus, but does not do a good job of sorting them. Many people sort manually in Windows Explorer, but it leads to several issues:
* **Broken icons:** People often forget to move the `.nfo` or `.png` alongside the `.fst`.
* **Updating and maintenance:** Re-installing or adding new plugins requires repeating the manual process.

## How I solved it!
This project provides two PowerShell 7 scripts that easily let you manage and sort your plugins.

1.  **`Generate-PluginCSV.ps1`**: Scans your "Installed" plugins and generates/updates a CSV mapping file. It guesses as best it can to categorize them and lets you override the mapping afterward.
2.  **`Organize-PluginDatabase.ps1`**: Reads the generated CSV and rebuilds your `Effects` and `Generators` folders.

The generation script also works after installing new plugins and will notify you how many entries in the CSV need to be manually updated. This ensures that adding new plugins won't disrupt your organization.
## How is this different from https://github.com/Magabes/FL-Studio-Automatic-Plugin-Organizer?
These scripts will allow you way more granular control over how you want to organize your plugins, and you can easily modify and update the csv script to easily change your organization.

---

## Prerequisites
* **Windows Only:** Currently only supported on Windows.
* **PowerShell 7**: Required for modern regex and path handling. [Install PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows?view=powershell-7.5).
* **Favorited Plugins**: You must have "favorited" your plugins in FL Studio (Flag as favorite) so they appear in the `...\Plugin database\Installed` folder.
* **User Data Folder**: You must know your FL Studio User Data path (typically `Documents\Image-Line\FL Studio\Presets\Plugin database`). You can find this by going to the FL Browser, right-clicking "Plugin Database," and selecting "Open."

---

## The Workflow

### 1. Generate & Guess
Run the `Generate-PluginCSV.ps1` script. It identifies every unique plugin you have favorited and attempts to guess the category based on keywords (e.g., `Pro-Q 3` -> `Effects\EQ and Filters;Effects\Vendors\FabFilter`). It appends new discoveries to your CSV without overwriting your manual work.

### 2. Refine in Excel/Calc
Open your mapping CSV. 
* **Name**: The `.fst` filename.
* **TargetPaths**: Semicolon-separated paths where the plugin should appear. You can have a plugin in both its vendor folder and an effects folder.
    * *Example:* `Effects\Dynamics;Effects\Vendors\FabFilter`

### 3. Deploy
Run the `Organize-PluginDatabase.ps1` script. Provide the path to your edited mapping CSV.
* It will prompt you to wipe your effect and generator directories. This is recommended to prevent duplicate entries; it will not remove any installed plugins.

---

<a name="get-started"></a>
## Get started!
1. Download the two PowerShell scripts or clone the repo: `git clone https://github.com/Vatnar/FLStudio-Plugin-Sorter`
2. Run the `Generate-PluginCSV.ps1` script and supply your database directory path.
3. Modify the mapping file to your liking. Use relative paths from the database directory path. Use semicolons (;) do add it to multiple places. See `ExampleMapping.csv`.
4. Run the `Organize-PluginDatabase.ps1` script with the modified mapping CSV.

---

## Tips 
* **Clean Slate:** When running the placement script, choose "Yes" to empty folders. This ensures your FL Studio menus match your CSV perfectly.
* **Redundancy is Speed:** Use the semicolon `;` to put your primary tools in multiple folders (e.g., a "Favorites" folder AND a "Functional" folder).
* **Backup:** Before your first run, back up your `Plugin database` folder.

---

## 🤝 Contributing & Customization

### Improving the Ruleset
The guessing logic is defined in the `Get-GuessedPath` function inside `Generate-PluginCSV.ps1`. 

* **Refining Categories:** If certain plugins are being misidentified, you can adjust the `-match` patterns in the **Functional Logic** blocks. We use standard Regex; for example, `comp|limit|gate` captures any plugin with those strings in the name.
* Defining regexes in a differnt file rather than in the ps1 is also a good idea as some reddit user pointed out. 


### Choosing Your Own Structure
If you want the script to sort plugins differently by default (e.g., placing all Native plugins in a `Stock` folder instead of `Image-Line`), you can modify the path strings directly in the script:
* Change `"$branch\Vendors\$($vendors[$pattern])"` to your preferred hierarchy.
* Modify the `$branch` detection if you want to separate "VFX" or "Controllers" into their own top-level folders.

### 📬 Pull Requests
Found a robust regex for a vendor or useful category then please submit a PR :(

---

## License
MIT. Use at your own risk. This script modifies your FL Studio preset files. Always maintain backups of your User Data Folder.
