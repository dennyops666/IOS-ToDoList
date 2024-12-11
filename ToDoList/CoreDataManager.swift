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
    
    public func save() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Task Operations
    public func createTask(title: String, notes: String?, dueDate: Date?, category: Category?) -> Task {
        let task = Task(context: viewContext)
        task.setValue(UUID(), forKey: "id")
        task.title = title
        task.notes = notes
        task.dueDate = dueDate
        task.category = category
        task.isCompleted = false
        save()
        return task
    }
    
    public func fetchTasks() -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching tasks: \(error)")
            return []
        }
    }
    
    public func updateTask(_ task: Task) {
        save()
    }
    
    public func deleteTask(_ task: Task) {
        viewContext.delete(task)
        save()
    }
    
    // MARK: - Category Operations
    public func createCategory(_ name: String) -> Category {
        let category = Category(context: viewContext)
        category.setValue(UUID(), forKey: "id")
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