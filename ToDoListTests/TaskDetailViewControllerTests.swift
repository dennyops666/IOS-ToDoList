import XCTest
@testable import ToDoList
import CoreData

class TaskDetailViewControllerTests: XCTestCase {
    
    var sut: TaskDetailViewController!
    var coreDataManager: CoreDataManager!
    var mockContainer: NSPersistentContainer!
    
    override func setUp() {
        super.setUp()
        
        // 创建内存数据存储
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        let container = NSPersistentContainer(name: "TestToDoList", managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { (description, error) in
            XCTAssertNil(error)
        }
        mockContainer = container
        coreDataManager = CoreDataManager()
        coreDataManager.context = container.viewContext
        
        // 创建 TaskDetailViewController
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        sut = storyboard.instantiateViewController(withIdentifier: "TaskDetailViewController") as? TaskDetailViewController
        sut.coreDataManager = coreDataManager
        
        // 加载视图
        sut.loadViewIfNeeded()
    }
    
    override func tearDown() {
        sut = nil
        coreDataManager = nil
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - 测试用例
    
    func testInitialState() {
        // 验证初始状态
        XCTAssertNotNil(sut.titleTextField)
        XCTAssertNotNil(sut.notesTextView)
        XCTAssertNotNil(sut.dueDatePicker)
        XCTAssertNotNil(sut.categoryButton)
        XCTAssertNotNil(sut.saveButton)
    }
    
    func testSaveNewTask() {
        // 设置任务信息
        sut.titleTextField.text = "测试任务"
        sut.notesTextView.text = "这是一个测试备注"
        let dueDate = Date()
        sut.dueDatePicker.date = dueDate
        
        // 保存任务
        sut.saveTask()
        
        // 验证任务是否被保存
        let tasks = coreDataManager.fetchTasks()
        XCTAssertEqual(tasks.count, 1)
        
        let savedTask = tasks.first
        XCTAssertEqual(savedTask?.title, "测试任务")
        XCTAssertEqual(savedTask?.notes, "这是一个测试备注")
        XCTAssertEqual(savedTask?.dueDate?.timeIntervalSince1970, dueDate.timeIntervalSince1970, accuracy: 1.0)
    }
    
    func testUpdateExistingTask() {
        // 创建一个现有任务
        let task = coreDataManager.createTask(title: "原始标题", notes: "原始备注")
        sut.task = task
        
        // 更新任务信息
        sut.titleTextField.text = "更新后的标题"
        sut.notesTextView.text = "更新后的备注"
        let newDueDate = Date()
        sut.dueDatePicker.date = newDueDate
        
        // 保存更新
        sut.saveTask()
        
        // 验证更新是否成功
        let updatedTask = coreDataManager.fetchTasks().first
        XCTAssertEqual(updatedTask?.title, "更新后的标题")
        XCTAssertEqual(updatedTask?.notes, "更新后的备注")
        XCTAssertEqual(updatedTask?.dueDate?.timeIntervalSince1970, newDueDate.timeIntervalSince1970, accuracy: 1.0)
    }
    
    func testDeleteTask() {
        // 创建一个任务
        let task = coreDataManager.createTask(title: "待删除任务", notes: "")
        sut.task = task
        
        // 删除任务
        sut.deleteTask()
        
        // 验证任务是否被删除
        let tasks = coreDataManager.fetchTasks()
        XCTAssertEqual(tasks.count, 0)
    }
    
    func testTaskValidation() {
        // 测试空标题
        sut.titleTextField.text = ""
        XCTAssertFalse(sut.isValidTask())
        
        // 测试有效标题
        sut.titleTextField.text = "有效标题"
        XCTAssertTrue(sut.isValidTask())
    }
    
    func testCategorySelection() {
        // 创建测试分类
        let category = coreDataManager.createCategory(name: "测试分类")
        
        // 模拟选择分类
        sut.selectedCategory = category
        
        // 保存任务
        sut.titleTextField.text = "测试任务"
        sut.saveTask()
        
        // 验证任务分类
        let savedTask = coreDataManager.fetchTasks().first
        XCTAssertEqual(savedTask?.category?.name, "测试分类")
    }
}
