import CoreData

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private init() {}
    
    // Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ToDoList")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Core Data Saving
    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Task Operations
    func createTask(title: String, notes: String?, dueDate: Date?, category: Category?) -> Task {
        let task = Task(context: viewContext)
        task.setValue(UUID(), forKey: "id")
        task.title = title
        task.notes = notes
        task.dueDate = dueDate
        task.category = category
        task.isCompleted = false
        saveContext()
        return task
    }
    
    func fetchTasks() -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching tasks: \(error)")
            return []
        }
    }
    
    func updateTask(_ task: Task) {
        saveContext()
    }
    
    func deleteTask(_ task: Task) {
        viewContext.delete(task)
        saveContext()
    }
    
    // MARK: - Category Operations
    func createCategory(_ name: String) -> Category {
        let category = Category(context: viewContext)
        category.setValue(UUID(), forKey: "id")
        category.name = name
        saveContext()
        return category
    }
    
    func fetchCategories() -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    func deleteCategory(_ category: Category) {
        viewContext.delete(category)
        saveContext()
    }
} 