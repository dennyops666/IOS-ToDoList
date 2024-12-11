import CoreData

class PersistenceController {
    // 静态实例
    static let shared = PersistenceController()
    
    // Core Data 容器
    let container: NSPersistentContainer
    
    // 初始化方法
    init() {
        container = NSPersistentContainer(name: "ToDoList")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
    }
    
    // 便捷访问 viewContext
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    // 保存上下文
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let error = error as NSError
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
} 