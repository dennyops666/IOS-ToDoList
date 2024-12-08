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
        
        // 清除所有现有数据
        let existingTasks = coreDataManager.fetchTasks()
        existingTasks.forEach { coreDataManager.deleteTask($0) }
        
        let existingCategories = coreDataManager.fetchCategories()
        existingCategories.forEach { coreDataManager.deleteCategory($0) }
    }
    
    override func tearDown() {
        coreDataManager = nil
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - 任务测试
    func testCreateTask() {
        // 创建任务
        let task = coreDataManager.createTask(title: "Test Task")
        
        // 验证任务属性
        XCTAssertEqual(task.title, "Test Task")
        XCTAssertFalse(task.isCompleted)
        XCTAssertNotNil(task.createdAt)
    }
    
    func testCreateTaskWithAllProperties() {
        // 创建分类
        let category = coreDataManager.createCategory(name: "工作")
        
        // 创建带有所有属性的任务
        let dueDate = Date()
        let task = coreDataManager.createTask(
            title: "完整任务",
            notes: "这是一个测试备注",
            dueDate: dueDate,
            category: category
        )
        
        // 验证所有属性
        XCTAssertEqual(task.title, "完整任务")
        XCTAssertEqual(task.notes, "这是一个测试备注")
        XCTAssertEqual(task.dueDate, dueDate)
        XCTAssertEqual(task.category, category)
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
    
    // MARK: - 分类测试
    func testCreateCategory() {
        // 创建分类
        let category = coreDataManager.createCategory(name: "工作")
        
        // 验证分类属性
        XCTAssertEqual(category.name, "工作")
        XCTAssertEqual(category.tasks?.count, 0)
    }
    
    func testFetchCategories() {
        // 验证初始状态为空
        XCTAssertEqual(coreDataManager.fetchCategories().count, 0)
        
        // 创建多个分类
        _ = coreDataManager.createCategory(name: "工作")
        _ = coreDataManager.createCategory(name: "生活")
        
        // 验证分类数量
        let categories = coreDataManager.fetchCategories()
        XCTAssertEqual(categories.count, 2)
    }
    
    func testDeleteCategory() {
        // 创建分类
        let category = coreDataManager.createCategory(name: "要删除的分类")
        
        // 确认分类已创建
        var categories = coreDataManager.fetchCategories()
        XCTAssertEqual(categories.count, 1)
        
        // 删除分类
        coreDataManager.deleteCategory(category)
        
        // 验证分类已删除
        categories = coreDataManager.fetchCategories()
        XCTAssertEqual(categories.count, 0)
    }
    
    func testTaskCategoryRelationship() {
        // 创建分类
        let category = coreDataManager.createCategory(name: "工作")
        
        // 创建任务并关联到分类
        let task = coreDataManager.createTask(
            title: "测试任务",
            category: category
        )
        
        // 验证关系
        XCTAssertEqual(task.category, category)
        XCTAssertEqual(category.tasks?.count, 1)
        XCTAssertEqual((category.tasks?.allObjects as? [Task])?.first?.title, "测试任务")
        
        // 测试分类删除后的任务状态
        coreDataManager.deleteCategory(category)
        XCTAssertNil(task.category, "分类删除后，任务的分类应为nil")
    }
} 
