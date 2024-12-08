import XCTest

class TaskListUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        
        // 添加启动参数，用于清理测试数据
        app.launchArguments = ["UI-Testing"]
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
        app.navigationBars["待办事项"].buttons["Add"].tap()
        
        // 输入任务标题
        let alertTextField = app.alerts["新增任务"].textFields.element
        alertTextField.typeText("测试任务")
        
        // 点击添加按钮
        app.alerts["新增任务"].buttons["添加"].tap()
        
        // 验证任务是否显示在列表中
        let taskText = app.tables.cells.staticTexts["测试任务"].firstMatch
        XCTAssertTrue(taskText.waitForExistence(timeout: 5), "任务未出现在列表中")
    }
    
    func testEditTask() {
        // 首先添加一个任务
        app.navigationBars["待办事项"].buttons["Add"].tap()
        app.alerts["新增任务"].textFields.element.typeText("待编辑任务")
        app.alerts["新增任务"].buttons["添加"].tap()
        
        // 等待任务出现并点击
        let taskText = app.tables.cells.staticTexts["待编辑任务"].firstMatch
        XCTAssertTrue(taskText.waitForExistence(timeout: 5), "任务未出现在列表中")
        taskText.tap()
        
        // 等待编辑界面加载并查找标题文本框
        let titleTextField = app.textFields["taskTitleTextField"]
        XCTAssertTrue(titleTextField.waitForExistence(timeout: 5), "无法找到任务标题输入框")
        
        // 修改任务标题
        titleTextField.tap()
        titleTextField.clearAndEnterText("已编辑的任务")
        
        // 保存更改
        app.navigationBars["编辑任务"].buttons["保存"].tap()
        
        // 验证更改是否生效
        XCTAssertTrue(app.tables.cells.staticTexts["已编辑的任务"].firstMatch.exists)
    }
    
    func testDeleteTask() {
        // 首先添加一个任务
        app.navigationBars["待办事项"].buttons["Add"].tap()
        app.alerts["新增任务"].textFields.element.typeText("待删除任务")
        app.alerts["新增任务"].buttons["添加"].tap()
        
        // 等待任务出现
        let taskText = app.tables.cells.staticTexts["待删除任务"].firstMatch
        XCTAssertTrue(taskText.waitForExistence(timeout: 5), "任务未出现在列表中")
        
        // 获取任务cell并左滑
        let cell = app.tables.cells.containing(.staticText, identifier: "待删除任务").firstMatch
        XCTAssertTrue(cell.exists, "找不到要删除的任务")
        cell.swipeLeft()
        
        // 等待删除按钮出现并点击
        let deleteButton = cell.buttons["删除"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "删除按钮未出现")
        deleteButton.tap()
        
        // 验证任务是否已被删除
        XCTAssertFalse(taskText.exists, "任务未被成功删除")
    }
    
    func testToggleTaskCompletion() {
        // 首先添加一个任务
        app.navigationBars["待办事项"].buttons["Add"].tap()
        app.alerts["新增任务"].textFields.element.typeText("测试完成状态")
        app.alerts["新增任务"].buttons["添加"].tap()
        
        // 等待任务出现在列表中
        let taskText = app.tables.cells.staticTexts["测试完成状态"].firstMatch
        XCTAssertTrue(taskText.waitForExistence(timeout: 5))
        
        // 获取包含该文本的第一个cell
        let cell = app.tables.cells.containing(.staticText, identifier: "测试完成状态").firstMatch
        XCTAssertTrue(cell.exists, "找不到包含指定文本的cell")
        
        // 左滑并点击完成
        cell.swipeLeft()
        
        // 等待完成按钮出现并点击
        let completeButton = cell.buttons["完成"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: 5), "找不到完成按钮")
        completeButton.tap()
        
        // 验证任务仍然存在
        XCTAssertTrue(taskText.exists)
        
        // 等待UI更新
        sleep(1)
        
        // 验证任务已标记为完成
        let completedCell = app.tables.cells.containing(.staticText, identifier: "测试完成状态").firstMatch
        XCTAssertTrue(completedCell.exists)
        XCTAssertEqual(completedCell.value as? String, "测试完成状态, 已完成")
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