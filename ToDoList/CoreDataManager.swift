import CoreData

// 使用命名空间来避免冲突
public enum Database {
    public static let shared = CoreDataStack()
}

// 重命名为 CoreDataStack 以避免冲突
public final class CoreDataStack {
    init() {}
    
    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ToDoList")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    public var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // 添加自定义错误类型
    public enum DatabaseError: Error {
        case saveFailed(Error)
        case fetchFailed(Error)
        case deleteFailed(Error)
        case invalidData
    }
    
    // 修改 save 方法，不返回 Result
    public func save() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
    
    // MARK: - Task Operations
    public func createTask(title: String, notes: String?, dueDate: Date?, category: Category?) -> Task {
        let task = Task(context: viewContext)
        task.title = title
        task.notes = notes
        task.dueDate = dueDate
        task.category = category
        task.isCompleted = false
        task.createdAt = Date()
        task.priority = 0
        save()
        return task
    }
    
    // 修改 fetchTasks 方法，使用可选值而不是 Result
    public func fetchTasks() -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }
    
    // 修改 updateTask 方法
    public func updateTask(_ task: Task) {
        if task.createdAt == nil {
            task.createdAt = Date()
        }
        save()
    }
    
    // 修改 deleteTask 方法
    public func deleteTask(_ task: Task) {
        viewContext.delete(task)
        save()
    }
    
    // MARK: - Category Operations
    public func createCategory(_ name: String) -> Category {
        let category = Category(context: viewContext)
        category.name = name
        save()
        return category
    }
    
    public func fetchCategories() -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    public func deleteCategory(_ category: Category) {
        viewContext.delete(category)
        save()
    }
    
    // MARK: - Validation Methods
    public func isTaskNameExists(_ name: String) -> Bool {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", name)
        
        do {
            let count = try viewContext.count(for: request)
            return count > 0
        } catch {
            print("Error checking task name: \(error)")
            return false
        }
    }
    
    public func isCategoryNameExists(_ name: String) -> Bool {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let count = try viewContext.count(for: request)
            return count > 0
        } catch {
            print("Error checking category name: \(error)")
            return false
        }
    }
} 