import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ToDoList")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Task操作
    func createTask(title: String, notes: String? = nil, dueDate: Date? = nil, category: Category? = nil) -> Task {
        let task = Task(context: context)
        task.title = title
        task.notes = notes
        task.dueDate = dueDate
        task.createdAt = Date()
        task.isCompleted = false
        task.category = category
        
        saveContext()
        return task
    }
    
    func fetchTasks(isCompleted: Bool? = nil) -> [Task] {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        
        if let isCompleted = isCompleted {
            fetchRequest.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: isCompleted))
        }
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "dueDate", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching tasks: \(error)")
            return []
        }
    }
    
    func updateTask(_ task: Task) {
        saveContext()
    }
    
    func deleteTask(_ task: Task) {
        context.delete(task)
        saveContext()
    }
    
    // MARK: - Category操作
    func createCategory(name: String, color: String? = nil) -> Category {
        let category = Category(context: context)
        category.name = name
        category.color = color
        
        saveContext()
        return category
    }
    
    func fetchCategories() -> [Category] {
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    func deleteCategory(_ category: Category) {
        context.delete(category)
        saveContext()
    }
    
    // MARK: - 名称重复检查
    func isTaskNameExists(_ taskName: String) -> Bool {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", taskName)
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking task name: \(error)")
            return false
        }
    }
    
    func isCategoryNameExists(_ name: String) -> Bool {
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking category name: \(error)")
            return false
        }
    }
    
    // MARK: - Core Data Saving support
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // 添加获取所有分类的方法
    func fetchAllCategories() -> [Category] {
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
} 