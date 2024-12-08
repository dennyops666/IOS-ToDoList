import XCTest
@testable import ToDoList
import CoreData

class CoreDataTests: XCTestCase {
    
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
        coreDataManager = CoreDataManager.shared
        coreDataManager.persistentContainer = container
        
        // 清除所有现有任务
        let existingTasks = coreDataManager.fetchTasks()
        existingTasks.forEach { coreDataManager.deleteTask($0) }
    }
    
    override func tearDown() {
        coreDataManager = nil
        mockContainer = nil
        super.tearDown()
    }
    
    func testCreateTask() {
        // 创建任务
        let task = coreDataManager.createTask(title: "Test Task")
        
        // 验证任务属性
        XCTAssertEqual(task.title, "Test Task")
        XCTAssertFalse(task.isCompleted)
        XCTAssertNotNil(task.createdAt)
    }
    
    func testFetchTasks() {
        // 验证初始状态为空
        XCTAssertEqual(coreDataManager.fetchTasks().count, 0)
        
        // 创建多个任务
        _ = coreDataManager.createTask(title: "任务1")
        let task2 = coreDataManager.createTask(title: "任务2")
        task2.isCompleted = true
        
        // 测试获取所有任务
        let allTasks = coreDataManager.fetchTasks()
        XCTAssertEqual(allTasks.count, 2)
        
        // 测试获取未完成任务
        let incompleteTasks = coreDataManager.fetchTasks(isCompleted: false)
        XCTAssertEqual(incompleteTasks.count, 1)
        XCTAssertEqual(incompleteTasks.first?.title, "任务1")
        
        // 测试获取已完成任务
        let completedTasks = coreDataManager.fetchTasks(isCompleted: true)
        XCTAssertEqual(completedTasks.count, 1)
        XCTAssertEqual(completedTasks.first?.title, "任务2")
    }
    
    func testUpdateTask() {
        // 创建任务
        let task = coreDataManager.createTask(title: "原始标题")
        
        // 更新任务
        task.title = "更新后的标题"
        task.notes = "测试备注"
        task.isCompleted = true
        coreDataManager.updateTask(task)
        
        // 重新获取任务验证更新
        let tasks = coreDataManager.fetchTasks()
        XCTAssertEqual(tasks.count, 1)
        let updatedTask = tasks.first
        XCTAssertEqual(updatedTask?.title, "更新后的标题")
        XCTAssertEqual(updatedTask?.notes, "测试备注")
        XCTAssertTrue(updatedTask?.isCompleted ?? false)
    }
    
    func testDeleteTask() {
        // 创建任务
        let task = coreDataManager.createTask(title: "要删除的任务")
        
        // 确认任务已创建
        var tasks = coreDataManager.fetchTasks()
        XCTAssertEqual(tasks.count, 1)
        
        // 删除任务
        coreDataManager.deleteTask(task)
        
        // 验证任务已删除
        tasks = coreDataManager.fetchTasks()
        XCTAssertEqual(tasks.count, 0)
    }
} 
