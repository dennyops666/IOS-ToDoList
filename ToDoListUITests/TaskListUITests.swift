import XCTest

class TaskListUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        
        // 添加启动参数，用于清理测试数据
        app.launchArguments = ["UI-Testing"]
        
        // 禁用性能指标收集
        app.launchEnvironment = [
            "UITEST_DISABLE_APP_LAUNCH_MEASUREMENT": "YES",
            "CA_DEBUG_TRANSACTIONS": "NO"
        ]
        
        app.launch()
        
        // 清理已有的任务
        let cells = app.tables.cells
        while cells.count > 0 {
            let firstCell = cells.firstMatch
            firstCell.swipeLeft()
            if app.buttons["删除"].waitForExistence(timeout: 5) {
                app.buttons["删除"].tap()
            }
        }
    }
    
    func testAddNewTask() {
        // 点击添加按钮
        let addButton = app.navigationBars.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        
        // 等待任务编辑界面出现
        let titleTextField = app.textFields["任务名称"]
        XCTAssertTrue(titleTextField.waitForExistence(timeout: 5))
        
        // 输入任务信息
        titleTextField.tap()
        titleTextField.typeText("基本任务测试")
        
        // 添加备注
        let notesTextView = app.textViews.firstMatch
        notesTextView.tap()
        notesTextView.typeText("这是一个基本任务的测试备注")
        
        // 点击保存按钮
        let saveButton = app.navigationBars.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()
        
        // 验证任务是否显示在列表中
        let taskCell = app.tables.cells.containing(.staticText, identifier: "基本任务测试").firstMatch
        XCTAssertTrue(taskCell.waitForExistence(timeout: 5))
    }
    
    func testAddTaskWithCategory() {
        // 首先创建一个分类
        let categoryButton = app.navigationBars.buttons.matching(identifier: "所有分类").firstMatch
        XCTAssertTrue(categoryButton.waitForExistence(timeout: 5))
        categoryButton.tap()
        
        let manageButton = app.sheets.buttons["管理分类..."]
        XCTAssertTrue(manageButton.waitForExistence(timeout: 5))
        manageButton.tap()
        
        let addCategoryButton = app.navigationBars["分类管理"].buttons["Add"]
        XCTAssertTrue(addCategoryButton.waitForExistence(timeout: 5))
        addCategoryButton.tap()
        
        // 等待并处理新增分类的文本输入
        let textField = app.textFields.firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("测试分类A")
        
        let addButton = app.buttons["添加"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        
        // 返回任务列表
        let backButton = app.navigationBars["分类管理"].buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap()
        
        // 创建新任务
        let addTaskButton = app.navigationBars.buttons["Add"]
        XCTAssertTrue(addTaskButton.waitForExistence(timeout: 5))
        addTaskButton.tap()
        
        // 输入任务标题
        let titleTextField = app.textFields["任务名称"]
        XCTAssertTrue(titleTextField.waitForExistence(timeout: 5))
        titleTextField.tap()
        titleTextField.typeText("分类A的测试任务")
        
        // 选择分类
        let selectCategoryButton = app.buttons["选择分类"]
        XCTAssertTrue(selectCategoryButton.waitForExistence(timeout: 5))
        selectCategoryButton.tap()
        
        // 等待分类选择表出现并选择
        let categorySheet = app.sheets["选择分类"]
        XCTAssertTrue(categorySheet.waitForExistence(timeout: 5))
        
        let workCategoryButton = categorySheet.buttons.element(boundBy: 1) // 第一个是"无分类"，第二个是"测试分类A"
        XCTAssertTrue(workCategoryButton.waitForExistence(timeout: 5))
        workCategoryButton.tap()
        
        // 保存任务
        let saveButton = app.navigationBars.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()
        
        // ���证任务是否显示在列表中
        let taskCell = app.tables.cells.containing(.staticText, identifier: "分类A的测试任务").firstMatch
        XCTAssertTrue(taskCell.waitForExistence(timeout: 5))
        XCTAssertTrue(taskCell.staticTexts["测试分类A"].exists)
    }
    
    func testFilterTasksByCategory() {
        // 首先创建一个分类和任务
        // 首先创建一个分类
        let categoryButton = app.navigationBars.buttons.matching(identifier: "所有分类").firstMatch
        XCTAssertTrue(categoryButton.waitForExistence(timeout: 5))
        categoryButton.tap()
        
        let manageButton = app.sheets.buttons["管理分类..."]
        XCTAssertTrue(manageButton.waitForExistence(timeout: 5))
        manageButton.tap()
        
        let addCategoryButton = app.navigationBars["分类管理"].buttons["Add"]
        XCTAssertTrue(addCategoryButton.waitForExistence(timeout: 5))
        addCategoryButton.tap()
        
        // 等待并处理新增分类的文本输入
        let textField = app.textFields.firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("测试分类B")
        
        let addButton = app.buttons["添加"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        
        // 返回任务列表
        let backButton = app.navigationBars["分类管理"].buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap()
        
        // 创建新任务
        let addTaskButton = app.navigationBars.buttons["Add"]
        XCTAssertTrue(addTaskButton.waitForExistence(timeout: 5))
        addTaskButton.tap()
        
        // 输入任务标题
        let titleTextField = app.textFields["任务名称"]
        XCTAssertTrue(titleTextField.waitForExistence(timeout: 5))
        titleTextField.tap()
        titleTextField.typeText("分类B的测试任务")
        
        // 选择分类
        let selectCategoryButton = app.buttons["选择分类"]
        XCTAssertTrue(selectCategoryButton.waitForExistence(timeout: 5))
        selectCategoryButton.tap()
        
        // 等待分类选择表出现并选择
        let categorySheet = app.sheets["选择分类"]
        XCTAssertTrue(categorySheet.waitForExistence(timeout: 5))
        
        let categoryBButton = categorySheet.buttons.element(boundBy: 1)
        XCTAssertTrue(categoryBButton.waitForExistence(timeout: 5))
        categoryBButton.tap()
        
        // 保存任务
        let saveButton = app.navigationBars.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()
        
        // 点击分类按钮进行筛选
        categoryButton.tap()
        
        // 选择"测试分类B"
        let filterSheet = app.sheets["选择分类"]
        XCTAssertTrue(filterSheet.waitForExistence(timeout: 5))
        
        let filterCategoryButton = filterSheet.buttons.element(boundBy: 1)
        XCTAssertTrue(filterCategoryButton.waitForExistence(timeout: 5))
        filterCategoryButton.tap()
        
        // 验证只显示该分类的任务
        let taskCell = app.tables.cells.containing(.staticText, identifier: "分类B的测试任务").firstMatch
        XCTAssertTrue(taskCell.waitForExistence(timeout: 5))
        XCTAssertEqual(app.tables.cells.count, 1)
        
        // 切换回所有任务
        let selectedCategoryButton = app.navigationBars.buttons.matching(identifier: "测试分类B").firstMatch
        XCTAssertTrue(selectedCategoryButton.waitForExistence(timeout: 5))
        selectedCategoryButton.tap()
        
        let allTasksButton = app.sheets["选择分类"].buttons["所有任务"]
        XCTAssertTrue(allTasksButton.waitForExistence(timeout: 5))
        allTasksButton.tap()
    }
    
    func testDeleteTask() {
        // 首先添加一个任务
        testAddNewTask()
        
        // 获取任务cell并左滑
        let cell = app.tables.cells.containing(.staticText, identifier: "基本任务测试").firstMatch
        XCTAssertTrue(cell.exists)
        cell.swipeLeft()
        
        // 等待删除按钮出现并点击
        let deleteButton = app.buttons["删除"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()
        
        // 验证任务是否已被删除
        XCTAssertFalse(cell.exists)
    }
    
    func testToggleTaskCompletion() {
        // 首先添加一个任务
        testAddNewTask()
        
        // 获取任务cell并左滑
        let cell = app.tables.cells.containing(.staticText, identifier: "基本任务测试").firstMatch
        XCTAssertTrue(cell.exists)
        cell.swipeLeft()
        
        // 点击完成按钮
        let completeButton = app.buttons["完成"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: 5))
        completeButton.tap()
        
        // 验证任务状态已更新
        let completedCell = app.tables.cells.containing(.staticText, identifier: "基本任务测试").firstMatch
        XCTAssertTrue(completedCell.exists)
        
        // 再次左滑并点击"未完成"
        completedCell.swipeLeft()
        let uncompleteButton = app.buttons["未完成"]
        XCTAssertTrue(uncompleteButton.waitForExistence(timeout: 5))
        uncompleteButton.tap()
    }
}

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        
        self.tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
} 