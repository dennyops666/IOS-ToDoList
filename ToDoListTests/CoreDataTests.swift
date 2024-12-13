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
        coreDataManager = CoreDataManager()
        coreDataManager.context = container.viewContext
        
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
        let task = coreDataManager.createTask(title: "Test Task", notes: "", dueDate: nil)
        
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
        _ = coreDataManager.createTask(title: "任务1", notes: "", dueDate: nil)
        let task2 = coreDataManager.createTask(title: "任务2", notes: "", dueDate: nil)
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
        let task = coreDataManager.createTask(title: "原始标题", notes: "", dueDate: nil)
        
        // 更新任务
        task.title = "更新后的标题"
        task.isCompleted = true
        
        // 保存更改
        coreDataManager.saveContext()
        
        // 验证更新
        let updatedTask = coreDataManager.fetchTasks().first
        XCTAssertEqual(updatedTask?.title, "更新后的标题")
        XCTAssertTrue(updatedTask?.isCompleted ?? false)
    }
    
    func testDeleteTask() {
        // 创建任务
        let task = coreDataManager.createTask(title: "待删除任务", notes: "", dueDate: nil)
        XCTAssertEqual(coreDataManager.fetchTasks().count, 1)
        
        // 删除任务
        coreDataManager.deleteTask(task)
        
        // 验证删除
        XCTAssertEqual(coreDataManager.fetchTasks().count, 0)
    }
    
    // MARK: - 分类测试
    
    func testCreateCategory() {
        // 创建分类
        let category = coreDataManager.createCategory(name: "测试分类")
        
        // 验证分类属性
        XCTAssertEqual(category.name, "测试分类")
        XCTAssertEqual(category.tasks?.count, 0)
    }
    
    func testFetchCategories() {
        // 验证初始状态为空
        XCTAssertEqual(coreDataManager.fetchCategories().count, 0)
        
        // 创建多个分类
        _ = coreDataManager.createCategory(name: "分类1")
        _ = coreDataManager.createCategory(name: "分类2")
        
        // 验证获取
        let categories = coreDataManager.fetchCategories()
        XCTAssertEqual(categories.count, 2)
    }
    
    func testUpdateCategory() {
        // 创建分类
        let category = coreDataManager.createCategory(name: "原始名称")
        
        // 更新分类
        category.name = "更新后的名称"
        
        // 保存更改
        coreDataManager.saveContext()
        
        // 验证更新
        let updatedCategory = coreDataManager.fetchCategories().first
        XCTAssertEqual(updatedCategory?.name, "更新后的名称")
    }
    
    func testDeleteCategory() {
        // 创建分类
        let category = coreDataManager.createCategory(name: "待删除分类")
        XCTAssertEqual(coreDataManager.fetchCategories().count, 1)
        
        // 删除分类
        coreDataManager.deleteCategory(category)
        
        // 验证删除
        XCTAssertEqual(coreDataManager.fetchCategories().count, 0)
    }
    
    func testCategoryTaskRelationship() {
        // 创建分类
        let category = coreDataManager.createCategory(name: "工作")
        
        // 创建任务并关联到分类
        let task1 = coreDataManager.createTask(
            title: "任务1",
            notes: "",
            dueDate: nil,
            category: category
        )
        
        let task2 = coreDataManager.createTask(
            title: "任务2",
            notes: "",
            dueDate: nil,
            category: category
        )
        
        // 验证关系
        XCTAssertEqual(category.tasks?.count, 2)
        XCTAssertEqual(task1.category, category)
        XCTAssertEqual(task2.category, category)
        
        // 测试解除关系
        task1.category = nil
        coreDataManager.saveContext()
        
        XCTAssertEqual(category.tasks?.count, 1)
        XCTAssertNil(task1.category)
    }
}
