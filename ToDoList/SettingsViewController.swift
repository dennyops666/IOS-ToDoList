import UIKit

class SettingsViewController: UITableViewController {
    
    private let themes = ["跟随系统", "浅色", "深色"]
    private let themeManager = ThemeManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "设置"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return themes.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "主题设置"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        
        let theme = themes[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = theme
        cell.contentConfiguration = content
        
        // 设置选中状态
        let currentTheme = themeManager.currentTheme
        let isSelected = (indexPath.row == 0 && currentTheme == .system) ||
                        (indexPath.row == 1 && currentTheme == .light) ||
                        (indexPath.row == 2 && currentTheme == .dark)
        
        cell.accessoryType = isSelected ? .checkmark : .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let newTheme: ThemeMode
        switch indexPath.row {
        case 0:
            newTheme = .system
        case 1:
            newTheme = .light
        case 2:
            newTheme = .dark
        default:
            return
        }
        
        themeManager.currentTheme = newTheme
        tableView.reloadData()
    }
} 