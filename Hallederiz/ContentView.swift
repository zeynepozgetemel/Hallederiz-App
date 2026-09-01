import SwiftUI
import Foundation
import UserNotifications
import UIKit
import PhotosUI

// Dinamik Gün Modeli
struct DayItem: Identifiable, Equatable {
    let id = UUID()
    let dayName: String
    let dayNumber: Int
    let dateString: String
    let date: Date
    
    static func generateWeek(for referenceDate: Date) -> [DayItem] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)
        guard let startOfWeek = calendar.date(from: components) else { return [] }
        
        var days: [DayItem] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "tr_TR")
                formatter.dateFormat = "EEE"
                let dayName = formatter.string(from: date).capitalized
                
                let number = calendar.component(.day, from: date)
                formatter.dateFormat = "yyyy-MM-dd"
                let dateString = formatter.string(from: date)
                
                days.append(DayItem(dayName: dayName, dayNumber: number, dateString: dateString, date: date))
            }
        }
        return days
    }
}

// Görev Modeli (KUSURSUZ SENKRONİZASYON İÇİN YENİLENDİ)
struct TaskItem: Identifiable, Equatable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    let dateString: String
    var reminderTime: String? = nil
    var sticker: String? = nil
    var isRoutineTask: Bool? = false
    var routineID: UUID? = nil
    var isManuallyAdded: Bool? = false
    var routineTaskID: UUID? = nil // ANA EKRAN İLE RUTİNİ BİRBİRİNE BAĞLAYAN ANAHTAR
}

// Rutin İçindeki Taslak Görev
struct RoutineTaskTemplate: Identifiable, Equatable, Codable {
    var id = UUID()
    var title: String
    var reminderTime: String? = nil
    var sticker: String? = "sparkles"
}

// Rutin Modeli
struct RoutineItem: Identifiable, Equatable, Codable {
    var id = UUID()
    var name: String
    var tasks: [RoutineTaskTemplate] = []
    var activeDays: [Int] = []
}

func getRoutineColor(for routineID: UUID?) -> Color {
    let palette = [
        Color(hex: "F3E5F5"), // Lila
        Color(hex: "FFE4E1"), // Şeftali Pembe
        Color(hex: "E6E6FA"), // Lavanta
        Color(hex: "E0FFFF"), // Açık Su Yeşili
        Color(hex: "FFF0F5"), // Pamuk Şeker
        Color(hex: "F0F8FF"), // Bebek Mavisi
        Color(hex: "FFF5EE")  // Narin Krem
    ]
    guard let idString = routineID?.uuidString else { return palette[0] }
    let asciiSum = idString.utf8.reduce(0) { $0 + Int($1) }
    return palette[asciiSum % palette.count]
}

let turkishSFSymbols: [String: [String]] = [
    "su": ["drop.fill", "cup.and.saucer.fill"],
    "güneş": ["sun.max.fill", "sunrise.fill"],
    "okul": ["book.fill", "graduationcap.fill", "backpack.fill"],
    "sınav": ["pencil.and.outline", "doc.text.fill", "highlighter"],
    "kedi": ["cat.fill", "pawprint.fill"],
    "köpek": ["pawprint.fill", "dog.fill"],
    "kod": ["laptopcomputer", "chevron.left.forwardslash.chevron.right", "cpu"],
    "yazılım": ["laptopcomputer", "cpu", "keyboard.fill"],
    "kalp": ["heart.fill", "suit.heart.fill", "heart.circle.fill"],
    "yıldız": ["star.fill", "sparkles", "moon.stars.fill"],
    "araba": ["car.fill", "bus.fill"],
    "ev": ["house.fill", "building.2.fill"],
    "oyun": ["gamecontroller.fill"],
    "para": ["creditcard.fill", "banknote.fill"],
    "kahve": ["cup.and.saucer.fill", "mug.fill"],
    "spor": ["figure.run", "dumbbell.fill", "sportscourt.fill"],
    "müzik": ["music.note", "headphones", "guitars.fill"],
    "yemek": ["fork.knife", "takeoutbag.and.cup.and.straw", "carrot.fill"],
    "ay": ["moon.fill", "moon.stars.fill", "cloud.moon.fill"],
    "bal": ["drop.fill", "hexagon.fill", "leaf.fill"],
    "çiçek": ["rosette", "leaf.fill", "camera.macro"],
    "alışveriş": ["cart.fill", "bag.fill", "basket.fill"],
    "tatil": ["sun.max.fill", "beach.umbrella.fill", "airplane"]
]

let commonSFSymbols = [
    "sparkles", "heart.fill", "star.fill", "pawprint.fill", "book.fill",
    "laptopcomputer", "drop.fill", "flame.fill", "car.fill", "house.fill",
    "cup.and.saucer.fill", "graduationcap.fill", "sun.max.fill"
]

struct ContentView: View {
    @State private var referenceDate: Date = Date()
    @State private var sampleDays: [DayItem] = DayItem.generateWeek(for: Date())
    @State private var selectedDayID: UUID?
    @State private var selectedDateString: String = ""
    
    @State private var tasks: [TaskItem] = []
    @State private var routines: [RoutineItem] = []
    
    @State private var showTaskForm: Bool = false
    @State private var taskToEdit: TaskItem? = nil
    @State private var showMonthCalendar: Bool = false
    @State private var showProfile: Bool = false
    @State private var showRoutinesManager: Bool = false
    @State private var showAddRoutineToTodaySheet: Bool = false
    
    @State private var weekDirection: Int = 1
    
    @AppStorage("profilePicData") private var profilePicData: Data = Data()
    
    let softPink = Color(hex: "FFD1DC")
    let cardPink = Color(hex: "FFF0F3")
    let hotPink  = Color(hex: "FF69B4")
    let darkPink = Color(hex: "900C3F")

    var body: some View {
        ZStack {
            softPink.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 12) {
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hallederiz! ✨")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(darkPink)
                        Text("Bugün neyi hallediyoruz?")
                            .font(.subheadline)
                            .foregroundColor(darkPink.opacity(0.8))
                    }
                    Spacer()
                    
                    Button(action: { showMonthCalendar = true }) {
                        Image(systemName: "calendar")
                            .font(.system(size: 24))
                            .foregroundColor(hotPink)
                            .padding(10)
                            .background(cardPink)
                            .clipShape(Circle())
                            .shadow(color: hotPink.opacity(0.2), radius: 3, x: 0, y: 2)
                    }
                    
                    Button(action: { showRoutinesManager = true }) {
                        Image(systemName: "repeat.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(hotPink)
                            .padding(10)
                            .background(cardPink)
                            .clipShape(Circle())
                            .shadow(color: hotPink.opacity(0.2), radius: 3, x: 0, y: 2)
                    }
                    
                    Button(action: { showProfile = true }) {
                        if let uiImage = UIImage(data: profilePicData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                                .shadow(color: hotPink.opacity(0.2), radius: 3, x: 0, y: 2)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(hotPink)
                                .padding(8)
                                .background(cardPink)
                                .clipShape(Circle())
                                .shadow(color: hotPink.opacity(0.2), radius: 3, x: 0, y: 2)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                HStack {
                    Text(currentMonthYear(from: referenceDate))
                        .font(.headline)
                        .foregroundColor(darkPink)
                        .animation(.none, value: referenceDate)
                    Spacer()
                }
                .padding(.horizontal)
                
                HStack(spacing: 8) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        weekDirection = -1
                        withAnimation(.easeInOut(duration: 0.35)) {
                            referenceDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: referenceDate) ?? referenceDate
                            sampleDays = DayItem.generateWeek(for: referenceDate)
                            if let first = sampleDays.first {
                                selectedDayID = first.id
                                selectedDateString = first.dateString
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(darkPink)
                            .padding(.horizontal, 4)
                    }
                    
                    ZStack {
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(sampleDays) { day in
                                        let isSelected = selectedDayID == day.id
                                        
                                        VStack(spacing: 8) {
                                            Text(day.dayName)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(isSelected ? cardPink : darkPink.opacity(0.7))
                                            
                                            Text("\(day.dayNumber)")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(isSelected ? cardPink : darkPink)
                                        }
                                        .frame(width: 60, height: 75)
                                        .background(isSelected ? hotPink : cardPink)
                                        .cornerRadius(16)
                                        .shadow(color: hotPink.opacity(isSelected ? 0.4 : 0.05), radius: 5, x: 0, y: 3)
                                        .scaleEffect(isSelected ? 1.05 : 1.0)
                                        .id(day.id)
                                        .onTapGesture {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            withAnimation(.spring()) {
                                                selectedDayID = day.id
                                                selectedDateString = day.dateString
                                                proxy.scrollTo(day.id, anchor: .center)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 4)
                            }
                            .onAppear {
                                if let selected = selectedDayID {
                                    proxy.scrollTo(selected, anchor: .center)
                                }
                            }
                            .onChange(of: selectedDayID) { _, newID in
                                if let newID = newID {
                                    withAnimation(.spring()) {
                                        proxy.scrollTo(newID, anchor: .center)
                                    }
                                }
                            }
                        }
                        .id(referenceDate)
                        .transition(.asymmetric(
                            insertion: .move(edge: weekDirection == 1 ? .trailing : .leading),
                            removal: .move(edge: weekDirection == 1 ? .leading : .trailing)
                        ))
                    }
                    .frame(height: 95)
                    .clipped()
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        weekDirection = 1
                        withAnimation(.easeInOut(duration: 0.35)) {
                            referenceDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: referenceDate) ?? referenceDate
                            sampleDays = DayItem.generateWeek(for: referenceDate)
                            if let first = sampleDays.first {
                                selectedDayID = first.id
                                selectedDateString = first.dateString
                            }
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(darkPink)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal)
                
                let currentDayTasks = tasks.filter { $0.dateString == selectedDateString }
                let completedCount = currentDayTasks.filter { $0.isCompleted }.count
                let totalCount = currentDayTasks.count
                let progress = totalCount > 0 ? CGFloat(completedCount) / CGFloat(totalCount) : 0.0
                
                VStack(spacing: 8) {
                    HStack {
                        Text(progressText(completed: completedCount, total: totalCount))
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(darkPink)
                        Spacer()
                        if totalCount > 0 {
                            Text("%\(Int(progress * 100))")
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(hotPink)
                        }
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(darkPink.opacity(0.15)).frame(height: 10)
                            Capsule()
                                .fill(LinearGradient(gradient: Gradient(colors: [hotPink.opacity(0.7), hotPink]), startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * progress, height: 10)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                        }
                    }
                    .frame(height: 10)
                    
                    let activeRoutineIDs = Array(Set(currentDayTasks.compactMap { $0.routineID }))
                    ForEach(activeRoutineIDs, id: \.self) { rID in
                        let rTasks = currentDayTasks.filter { $0.routineID == rID }
                        let rComp = rTasks.filter { $0.isCompleted }.count
                        let rTot = rTasks.count
                        let rProg = rTot > 0 ? CGFloat(rComp) / CGFloat(rTot) : 0.0
                        
                        if let rName = routines.first(where: { $0.id == rID })?.name {
                            VStack(spacing: 6) {
                                HStack {
                                    Text(rComp == rTot && rTot > 0 ? "\(rName) halledildi! 🥳" : "\(rName) devam ediyor ✨")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(darkPink.opacity(0.8))
                                    Spacer()
                                    if rTot > 0 {
                                        Text("%\(Int(rProg * 100))")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(hotPink.opacity(0.8))
                                    }
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(darkPink.opacity(0.10)).frame(height: 6)
                                        Capsule()
                                            .fill(LinearGradient(gradient: Gradient(colors: [hotPink.opacity(0.5), hotPink]), startPoint: .leading, endPoint: .trailing))
                                            .frame(width: geo.size.width * rProg, height: 6)
                                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: rProg)
                                    }
                                }
                                .frame(height: 6)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
                
                VStack {
                    if currentDayTasks.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 52))
                                .foregroundColor(darkPink.opacity(0.4))
                            Text("Bugün henüz hiçbir şey eklenmemiş.\nSağ alt köşeden hemen halledelim! ✨")
                                .font(.body)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .foregroundColor(darkPink.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        List {
                            Section {
                                ForEach(currentDayTasks) { task in
                                    TaskRowView(task: task, hotPink: hotPink, darkPink: darkPink, cardPink: cardPink, onToggle: {
                                        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                                            tasks[index].isCompleted.toggle()
                                            if tasks[index].isCompleted { cancelNotification(for: task) }
                                            saveTasks()
                                        }
                                    }, onEdit: {
                                        taskToEdit = task
                                    })
                                    .listRowBackground((task.isRoutineTask ?? false) ? getRoutineColor(for: task.routineID) : cardPink)
                                    .listRowSeparator(.hidden)
                                }
                                .onMove(perform: { indices, newOffset in
                                    var dayTasks = tasks.filter { $0.dateString == selectedDateString }
                                    dayTasks.move(fromOffsets: indices, toOffset: newOffset)
                                    tasks.removeAll { $0.dateString == selectedDateString }
                                    tasks.append(contentsOf: dayTasks)
                                    saveTasks()
                                })
                                .onDelete(perform: { indexSet in
                                    let dayTasks = tasks.filter { $0.dateString == selectedDateString }
                                    for index in indexSet {
                                        let taskToDelete = dayTasks[index]
                                        cancelNotification(for: taskToDelete)
                                        if let mainIndex = tasks.firstIndex(where: { $0.id == taskToDelete.id }) {
                                            tasks.remove(at: mainIndex)
                                        }
                                    }
                                    saveTasks()
                                })
                            }
                            
                            Section {
                                Color.clear
                                    .frame(height: 85)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                }
                Spacer()
            }
            
            // KAPSÜL BUTON ALANI
            VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: 0) {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        if !routines.isEmpty {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                showAddRoutineToTodaySheet = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "repeat.circle.fill")
                                        .font(.system(size: 22))
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .background(hotPink)
                                .clipShape(Capsule())
                                .shadow(color: hotPink.opacity(0.4), radius: 5, x: 0, y: 3)
                            }
                        }
                        
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showTaskForm = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 65, height: 65)
                                .background(hotPink)
                                .clipShape(Circle())
                                .shadow(color: hotPink.opacity(0.5), radius: 8, x: 0, y: 5)
                        }
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(isPresented: $showTaskForm) {
            TaskFormSheet(isEditing: false, initialTask: nil, selectedDate: selectedDateString, hotPink: hotPink, darkPink: darkPink, cardPink: cardPink, softPink: softPink, onSave: { newTask in
                tasks.append(newTask)
                saveTasks()
                if newTask.reminderTime != nil { scheduleNotification(for: newTask) }
                showTaskForm = false
            }, onCancel: { showTaskForm = false })
        }
        .sheet(item: $taskToEdit) { task in
            TaskFormSheet(isEditing: true, initialTask: task, selectedDate: task.dateString, hotPink: hotPink, darkPink: darkPink, cardPink: cardPink, softPink: softPink, onSave: { updatedTask in
                if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                    cancelNotification(for: tasks[index])
                    tasks[index] = updatedTask
                    saveTasks()
                    if updatedTask.reminderTime != nil { scheduleNotification(for: updatedTask) }
                }
                taskToEdit = nil
            }, onCancel: { taskToEdit = nil })
        }
        .sheet(isPresented: $showMonthCalendar) {
            MonthCalendarView(tempSelectedDate: referenceDate, hotPink: hotPink, darkPink: darkPink, softPink: softPink) { newDate in
                weekDirection = newDate > referenceDate ? 1 : -1
                withAnimation(.easeInOut(duration: 0.35)) {
                    referenceDate = newDate
                    sampleDays = DayItem.generateWeek(for: newDate)
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    selectedDateString = formatter.string(from: newDate)
                    
                    if let matchedDay = sampleDays.first(where: { $0.dateString == selectedDateString }) {
                        selectedDayID = matchedDay.id
                    }
                }
                showMonthCalendar = false
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(tasks: tasks, hotPink: hotPink, darkPink: darkPink, cardPink: cardPink, softPink: softPink)
        }
        .sheet(isPresented: $showRoutinesManager) {
            RoutinesManagerView(routines: $routines, tasks: $tasks, selectedDateString: selectedDateString, hotPink: hotPink, darkPink: darkPink, cardPink: cardPink, softPink: softPink, onSave: {
                saveRoutines()
                saveTasks()
                if let matchedDay = sampleDays.first(where: { $0.dateString == selectedDateString }) {
                    checkAndAutoAddRoutines(for: selectedDateString, date: matchedDay.date)
                }
            })
        }
        .sheet(isPresented: $showAddRoutineToTodaySheet) {
            AddRoutineToTodaySheet(routines: routines, tasks: $tasks, selectedDateString: selectedDateString, hotPink: hotPink, darkPink: darkPink, cardPink: cardPink, softPink: softPink, onSave: {
                saveTasks()
            })
        }
        .onChange(of: selectedDateString) { _, newDateString in
            if let matchedDay = sampleDays.first(where: { $0.dateString == newDateString }) {
                checkAndAutoAddRoutines(for: newDateString, date: matchedDay.date)
            }
        }
        .onAppear {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayString = formatter.string(from: Date())
            
            if let todayItem = sampleDays.first(where: { $0.dateString == todayString }) {
                selectedDayID = todayItem.id
                selectedDateString = todayItem.dateString
            }
            loadTasks()
            loadRoutines()
            
            if let matchedDay = sampleDays.first(where: { $0.dateString == selectedDateString }) {
                checkAndAutoAddRoutines(for: selectedDateString, date: matchedDay.date)
            }
            
            requestNotificationPermission()
        }
    }
    
    // GÜNCELLENMİŞ ZEKİ RUTİN SENKRONİZASYONU (Saniye Saniyesine Günceller)
    func checkAndAutoAddRoutines(for dateStr: String, date: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)
        
        if targetDate < today { return }
        
        let weekday = calendar.component(.weekday, from: date)
        var modified = false
        
        for routine in routines {
            let shouldBeActive = routine.activeDays.contains(weekday)
            let existingTasksForRoutine = tasks.filter { $0.routineID == routine.id && $0.dateString == dateStr && ($0.isRoutineTask == true) }
            let isManuallyPresent = existingTasksForRoutine.contains { $0.isManuallyAdded == true }
            
            if shouldBeActive || isManuallyPresent {
                let templateIDs = Set(routine.tasks.map { $0.id })
                
                // 1. Rutinden silinmiş görevleri ana ekrandan temizle
                for task in existingTasksForRoutine {
                    let isOrphanedByTID = task.routineTaskID != nil && !templateIDs.contains(task.routineTaskID!)
                    let isOrphanedByTitle = task.routineTaskID == nil && !routine.tasks.contains(where: { $0.title == task.title })
                    
                    if isOrphanedByTID || isOrphanedByTitle {
                        cancelNotification(for: task)
                        tasks.removeAll { $0.id == task.id }
                        modified = true
                    }
                }
                
                // 2. Mevcutları Güncelle veya Yeni Eklenenleri Ekle
                for t in routine.tasks {
                    if let index = tasks.firstIndex(where: { ($0.routineTaskID == t.id || ($0.routineTaskID == nil && $0.title == t.title)) && $0.dateString == dateStr && $0.routineID == routine.id }) {
                        
                        // Eski veriye kimlik kazandır (Migration)
                        if tasks[index].routineTaskID == nil {
                            tasks[index].routineTaskID = t.id
                            modified = true
                        }
                        
                        // Güncelleme kontrolü
                        if tasks[index].title != t.title || tasks[index].sticker != t.sticker || tasks[index].reminderTime != t.reminderTime {
                            tasks[index].title = t.title
                            tasks[index].sticker = t.sticker
                            if tasks[index].reminderTime != t.reminderTime {
                                cancelNotification(for: tasks[index])
                                tasks[index].reminderTime = t.reminderTime
                                if t.reminderTime != nil && !tasks[index].isCompleted {
                                    scheduleNotification(for: tasks[index])
                                }
                            }
                            modified = true
                        }
                    } else {
                        // Yeni görev eklenmişse ana ekrana da yansıt
                        let isManual = !shouldBeActive
                        let newTask = TaskItem(
                            id: UUID(),
                            title: t.title,
                            isCompleted: false,
                            dateString: dateStr,
                            reminderTime: t.reminderTime,
                            sticker: t.sticker,
                            isRoutineTask: true,
                            routineID: routine.id,
                            isManuallyAdded: isManual,
                            routineTaskID: t.id
                        )
                        tasks.append(newTask)
                        if newTask.reminderTime != nil { scheduleNotification(for: newTask) }
                        modified = true
                    }
                }
            } else {
                let autoAddedTasks = existingTasksForRoutine.filter { $0.isManuallyAdded != true }
                for task in autoAddedTasks {
                    cancelNotification(for: task)
                    tasks.removeAll { $0.id == task.id }
                    modified = true
                }
            }
        }
        if modified { saveTasks() }
    }
    
    func currentMonthYear(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).capitalized
    }
    
    func progressText(completed: Int, total: Int) -> String {
        if total == 0 { return "Hadi, bugünü planlayalım! 🌸" }
        if completed == 0 { return "Görevler seni bekliyor! ✨" }
        if completed == total { return "Her şey halledildi, harikasın! 💅💖" }
        if CGFloat(completed) / CGFloat(total) >= 0.5 { return "Günün yarısı bitti bile! 🚀" }
        return "Harika gidiyorsun kızım! 🎀"
    }
    
    func saveTasks() { if let encoded = try? JSONEncoder().encode(tasks) { UserDefaults.standard.set(encoded, forKey: "saved_tasks") } }
    func loadTasks() { if let savedData = UserDefaults.standard.data(forKey: "saved_tasks"), let decoded = try? JSONDecoder().decode([TaskItem].self, from: savedData) { tasks = decoded } }
    func saveRoutines() { if let encoded = try? JSONEncoder().encode(routines) { UserDefaults.standard.set(encoded, forKey: "saved_routines") } }
    func loadRoutines() { if let savedData = UserDefaults.standard.data(forKey: "saved_routines"), let decoded = try? JSONDecoder().decode([RoutineItem].self, from: savedData) { routines = decoded } }
    
    func requestNotificationPermission() { UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in } }
    
    func scheduleNotification(for task: TaskItem) {
        guard let timeStr = task.reminderTime else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let time = formatter.date(from: timeStr) else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let taskDate = dateFormatter.date(from: task.dateString) else { return }
        let content = UNMutableNotificationContent()
        content.title = "Hallederiz! 💅✨"
        content.body = "Kalk kız, şunu halletme vakti geldi: \(task.title)"
        content.sound = .default
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var triggerDateComponents = calendar.dateComponents([.year, .month, .day], from: taskDate)
        triggerDateComponents.hour = timeComponents.hour
        triggerDateComponents.minute = timeComponents.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    func cancelNotification(for task: TaskItem) { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString]) }
}

// MARK: - BUGÜNE RUTİN EKLEME SAYFASI
struct AddRoutineToTodaySheet: View {
    let routines: [RoutineItem]
    @Binding var tasks: [TaskItem]
    let selectedDateString: String
    
    let hotPink: Color
    let darkPink: Color
    let cardPink: Color
    let softPink: Color
    let onSave: () -> Void
    
    @State private var recentlyAddedIDs: Set<UUID> = []
    
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 3)
                .fill(darkPink.opacity(0.2))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text("Bugüne Rutin Ekle ✨")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(darkPink)
            
            if routines.isEmpty {
                Spacer()
                Text("Kayıtlı rutinin yok.\nÖnce Rutinler sayfasından oluştur! 🎀")
                    .multilineTextAlignment(.center)
                    .foregroundColor(darkPink.opacity(0.6))
                Spacer()
            } else {
                List {
                    ForEach(routines) { routine in
                        let isAlreadyAdded = tasks.contains { $0.routineID == routine.id && $0.dateString == selectedDateString }
                        
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            if !isAlreadyAdded {
                                for t in routine.tasks {
                                    let newTask = TaskItem(
                                        id: UUID(),
                                        title: t.title,
                                        isCompleted: false,
                                        dateString: selectedDateString,
                                        reminderTime: t.reminderTime,
                                        sticker: t.sticker,
                                        isRoutineTask: true,
                                        routineID: routine.id,
                                        isManuallyAdded: true,
                                        routineTaskID: t.id
                                    )
                                    tasks.append(newTask)
                                }
                                onSave()
                            }
                            
                            withAnimation { _ = recentlyAddedIDs.insert(routine.id) }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation { _ = recentlyAddedIDs.remove(routine.id) }
                            }
                        }) {
                            HStack {
                                Text(routine.name)
                                    .font(.headline)
                                    .foregroundColor(darkPink)
                                Spacer()
                                if recentlyAddedIDs.contains(routine.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                        .transition(.scale)
                                } else if isAlreadyAdded {
                                    Image(systemName: "checkmark.circle")
                                        .font(.title2)
                                        .foregroundColor(hotPink)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(hotPink)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(getRoutineColor(for: routine.id))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if isAlreadyAdded {
                                Button(role: .destructive) {
                                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                    tasks.removeAll { $0.routineID == routine.id && $0.dateString == selectedDateString }
                                    onSave()
                                } label: {
                                    Label("Bugünden Kaldır", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(softPink.ignoresSafeArea())
        .presentationDetents([.fraction(0.65), .large])
    }
}

// MARK: - RUTİNLER YÖNETİM SAYFASI
struct RoutinesManagerView: View {
    @Binding var routines: [RoutineItem]
    @Binding var tasks: [TaskItem]
    let selectedDateString: String
    let hotPink: Color
    let darkPink: Color
    let cardPink: Color
    let softPink: Color
    let onSave: () -> Void
    
    @State private var editingRoutine: RoutineItem? = nil
    @State private var isNewRoutine = false
    
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 3)
                .fill(darkPink.opacity(0.2))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text("Rutinlerim 🎀")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(darkPink)
            
            if routines.isEmpty {
                Spacer()
                Text("Henüz hiç rutin eklemedin.\nHemen bir tane oluştur! ✨")
                    .multilineTextAlignment(.center)
                    .foregroundColor(darkPink.opacity(0.6))
                Spacer()
            } else {
                List {
                    ForEach(routines) { routine in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(routine.name)
                                    .font(.headline)
                                    .foregroundColor(darkPink)
                                Spacer()
                                Button(action: {
                                    editingRoutine = routine
                                    isNewRoutine = false
                                }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(hotPink)
                                }
                            }
                            Text("\(routine.tasks.count) Görev")
                                .font(.caption)
                                .foregroundColor(darkPink.opacity(0.7))
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(getRoutineColor(for: routine.id))
                    }
                    .onDelete { indexSet in
                        routines.remove(atOffsets: indexSet)
                        onSave()
                    }
                }
                .scrollContentBackground(.hidden)
            }
            
            Button(action: {
                editingRoutine = RoutineItem(name: "")
                isNewRoutine = true
            }) {
                Text("Yeni Rutin Oluştur ✨")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(hotPink)
                    .cornerRadius(16)
                    .shadow(color: hotPink.opacity(0.4), radius: 5, x: 0, y: 3)
            }
            .padding()
        }
        .background(softPink.ignoresSafeArea())
        .sheet(item: $editingRoutine) { routine in
            RoutineEditView(initialRoutine: routine, isNew: isNewRoutine, hotPink: hotPink, darkPink: darkPink, cardPink: cardPink, softPink: softPink, onSave: { updatedRoutine in
                if isNewRoutine {
                    routines.append(updatedRoutine)
                } else if let idx = routines.firstIndex(where: { $0.id == updatedRoutine.id }) {
                    routines[idx] = updatedRoutine
                }
                onSave()
                editingRoutine = nil
            })
            .id(routine.id)
        }
    }
}

// MARK: - RUTİN DÜZENLEME EKRANI
struct RoutineEditView: View {
    var initialRoutine: RoutineItem
    @State private var routine: RoutineItem
    let isNew: Bool
    let hotPink: Color
    let darkPink: Color
    let cardPink: Color
    let softPink: Color
    let onSave: (RoutineItem) -> Void
    
    @State private var showNewTaskForm = false
    @State private var editingTask: RoutineTaskTemplate? = nil
    @State private var isEveryday = false
    
    let days = [(2,"Pzt"), (3,"Sal"), (4,"Çar"), (5,"Per"), (6,"Cum"), (7,"Cmt"), (1,"Paz")]
    
    init(initialRoutine: RoutineItem, isNew: Bool, hotPink: Color, darkPink: Color, cardPink: Color, softPink: Color, onSave: @escaping (RoutineItem) -> Void) {
        self.initialRoutine = initialRoutine
        _routine = State(initialValue: initialRoutine)
        self.isNew = isNew
        self.hotPink = hotPink
        self.darkPink = darkPink
        self.cardPink = cardPink
        self.softPink = softPink
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 3)
                .fill(darkPink.opacity(0.2))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text(isNew ? "Yeni Rutin ✨" : "Rutini Düzenle 🎀")
                .font(.headline)
                .foregroundColor(darkPink)
            
            TextField("", text: $routine.name, prompt: Text("Rutin Adı (örn: Sabah Rutini)").foregroundColor(darkPink.opacity(0.5)))
                .padding(14)
                .background(cardPink)
                .cornerRadius(14)
                .foregroundColor(darkPink)
                .padding(.horizontal)
                .contentShape(Rectangle())
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Her Gün Otomatik Ekle", isOn: $isEveryday)
                    .toggleStyle(SwitchToggleStyle(tint: hotPink))
                    .foregroundColor(darkPink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(cardPink)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .onChange(of: isEveryday) { _, newValue in
                        routine.activeDays = newValue ? [1,2,3,4,5,6,7] : []
                    }
                
                if !isEveryday {
                    Text("Hangi Günler Otomatik Eklensin?")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(darkPink)
                        .padding(.horizontal)
                        .padding(.top, 4)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(days, id: \.0) { day in
                                let isSelected = routine.activeDays.contains(day.0)
                                Button(action: {
                                    if isSelected {
                                        routine.activeDays.removeAll(where: {$0 == day.0})
                                    } else {
                                        routine.activeDays.append(day.0)
                                    }
                                }) {
                                    Text(day.1)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(isSelected ? .white : darkPink)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(isSelected ? hotPink : cardPink)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            HStack {
                Text("Görevler")
                    .font(.headline)
                    .foregroundColor(darkPink)
                Spacer()
                Button(action: {
                    editingTask = nil
                    showNewTaskForm = true
                }) {
                    Text("+ Yeni Görev")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(hotPink)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            if routine.tasks.isEmpty {
                Spacer()
                Text("Bu rutine ait görev yok.")
                    .foregroundColor(darkPink.opacity(0.6))
                Spacer()
            } else {
                List {
                    ForEach(routine.tasks) { task in
                        HStack {
                            if let s = task.sticker {
                                Image(systemName: s)
                                    .foregroundColor(hotPink)
                            }
                            VStack(alignment: .leading) {
                                Text(task.title)
                                    .foregroundColor(darkPink)
                                if let time = task.reminderTime {
                                    Text(time)
                                        .font(.caption2)
                                        .foregroundColor(darkPink.opacity(0.6))
                                }
                            }
                            Spacer()
                            Button(action: {
                                editingTask = task
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(darkPink.opacity(0.5))
                            }
                        }
                        .listRowBackground(cardPink)
                    }
                    .onDelete { routine.tasks.remove(atOffsets: $0) }
                }
                .scrollContentBackground(.hidden)
            }
            
            Button(action: {
                guard !routine.name.isEmpty else { return }
                onSave(routine)
            }) {
                Text(isNew ? "Rutini Kaydet 🚀" : "Değişiklikleri Kaydet 💅")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(hotPink)
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(softPink.ignoresSafeArea())
        .onAppear {
            routine = initialRoutine
            isEveryday = routine.activeDays.count == 7
        }
        .sheet(isPresented: $showNewTaskForm) {
            RoutineTaskFormSheet(initialTask: nil, hotPink: hotPink, darkPink: darkPink, cardPink: cardPink, softPink: softPink, onSave: { newTask in
                routine.tasks.append(newTask)
                showNewTaskForm = false
            })
        }
        .sheet(item: $editingTask) { task in
            RoutineTaskFormSheet(initialTask: task, hotPink: hotPink, darkPink: darkPink, cardPink: cardPink, softPink: softPink, onSave: { updatedTask in
                if let idx = routine.tasks.firstIndex(where: {$0.id == updatedTask.id}) {
                    routine.tasks[idx] = updatedTask
                }
                editingTask = nil
            })
        }
    }
}

// MARK: - RUTİN GÖREVİ EKLEME MİNİ FORMU
struct RoutineTaskFormSheet: View {
    let initialTask: RoutineTaskTemplate?
    let hotPink: Color
    let darkPink: Color
    let cardPink: Color
    let softPink: Color
    let onSave: (RoutineTaskTemplate) -> Void
    
    @State private var title: String = ""
    @State private var hasReminder: Bool = false
    @State private var selectedTime: Date = Date()
    @State private var selectedSticker: String = "sparkles"
    @State private var symbolSearchQuery: String = ""
    
    var filteredSymbols: [String] {
        let query = symbolSearchQuery.lowercased().trimmingCharacters(in: .whitespaces)
        if query.isEmpty { return commonSFSymbols }
        
        var results: [String] = []
        for (turkishKeyword, symbols) in turkishSFSymbols {
            if turkishKeyword.contains(query) { results.append(contentsOf: symbols) }
        }
        let englishResults = commonSFSymbols.filter { $0.contains(query) }
        results.append(contentsOf: englishResults)
        
        if !results.contains(query) { results.insert(query, at: 0) }
        return Array(NSOrderedSet(array: results)) as! [String]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 3)
                .fill(darkPink.opacity(0.2))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text("Rutin Görevi ✨")
                .font(.headline)
                .foregroundColor(darkPink)
            
            TextField("", text: $title, prompt: Text("Görev Adı...").foregroundColor(darkPink.opacity(0.5)))
                .padding(14)
                .background(cardPink)
                .cornerRadius(14)
                .foregroundColor(darkPink)
                .padding(.horizontal)
                .contentShape(Rectangle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Çıkartma Seç")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(darkPink)
                    .padding(.horizontal)
                
                TextField("", text: $symbolSearchQuery, prompt: Text("Çıkartma ara...").foregroundColor(darkPink.opacity(0.5)))
                    .padding(10)
                    .background(cardPink)
                    .cornerRadius(10)
                    .foregroundColor(darkPink)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filteredSymbols, id: \.self) { symbol in
                            Button(action: {
                                selectedSticker = symbol
                            }) {
                                Image(systemName: symbol)
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(darkPink)
                                    .background(selectedSticker == symbol ? hotPink.opacity(0.2) : cardPink)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(hotPink, lineWidth: selectedSticker == symbol ? 2 : 0)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                }
            }
            
            VStack(spacing: 12) {
                Toggle(isOn: $hasReminder.animation(.easeInOut)) {
                    Text("Anımsatıcı ekle ⏰")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(darkPink)
                }
                .toggleStyle(SwitchToggleStyle(tint: hotPink))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(cardPink)
                .cornerRadius(12)
                .padding(.horizontal)
                
                if hasReminder {
                    HStack {
                        Text("Saati Seç:")
                            .font(.subheadline)
                            .foregroundColor(darkPink)
                        Spacer()
                        DatePicker("Saat", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(hotPink)
                    }
                    .padding(.horizontal, 24)
                }
            }
            Spacer()
            Button(action: {
                guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                var formattedTime: String? = nil
                if hasReminder {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    formattedTime = formatter.string(from: selectedTime)
                }
                let newTask = RoutineTaskTemplate(
                    id: initialTask?.id ?? UUID(),
                    title: title,
                    reminderTime: formattedTime,
                    sticker: selectedSticker
                )
                onSave(newTask)
            }) {
                Text("Kaydet 💅")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(hotPink)
                    .cornerRadius(16)
                    .shadow(color: hotPink.opacity(0.4), radius: 5, x: 0, y: 3)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(softPink.ignoresSafeArea())
        .onAppear {
            if let t = initialTask {
                title = t.title
                if let s = t.sticker { selectedSticker = s }
                if let rm = t.reminderTime {
                    hasReminder = true
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    if let pd = formatter.date(from: rm) { selectedTime = pd }
                } else {
                    hasReminder = false
                }
            } else {
                title = ""
                selectedSticker = "sparkles"
                hasReminder = false
                selectedTime = Date()
            }
        }
    }
}

// MARK: - TAKVİM
struct MonthCalendarView: View {
    @State var tempSelectedDate: Date
    let hotPink: Color
    let darkPink: Color
    let softPink: Color
    let onDateSelected: (Date) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 3)
                .fill(darkPink.opacity(0.2))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text("Tüm Ayı Gör ✨")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(darkPink)
            
            DatePicker("Tarih Seç", selection: $tempSelectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(hotPink)
                .environment(\.colorScheme, .light)
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal)
            
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onDateSelected(tempSelectedDate)
            }) {
                Text("Seçili Güne Git 🚀")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(hotPink)
                    .cornerRadius(16)
                    .shadow(color: hotPink.opacity(0.4), radius: 5, x: 0, y: 3)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(softPink.ignoresSafeArea())
        .presentationDetents([.fraction(0.65), .large])
    }
}

// MARK: - PROFİL SAYFASI
struct ProfileView: View {
    let tasks: [TaskItem]
    let hotPink: Color
    let darkPink: Color
    let cardPink: Color
    let softPink: Color
    
    @AppStorage("userName") private var userName: String = "Kullanıcı"
    @AppStorage("profilePicData") private var profilePicData: Data = Data()
    @State private var photoItem: PhotosPickerItem? = nil
    
    @FocusState private var isNameFocused: Bool
    
    var weeklyCount: Int {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return tasks.filter { task in
            guard task.isCompleted, let d = formatter.date(from: task.dateString) else { return false }
            return calendar.isDate(d, equalTo: Date(), toGranularity: .weekOfYear)
        }.count
    }
    
    var monthlyCount: Int {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return tasks.filter { task in
            guard task.isCompleted, let d = formatter.date(from: task.dateString) else { return false }
            return calendar.isDate(d, equalTo: Date(), toGranularity: .month)
        }.count
    }
    
    var yearlyCount: Int {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return tasks.filter { task in
            guard task.isCompleted, let d = formatter.date(from: task.dateString) else { return false }
            return calendar.isDate(d, equalTo: Date(), toGranularity: .year)
        }.count
    }
    
    var earnedBadges: [String] {
        var badges: [String] = []
        let completedStickers = tasks.filter { $0.isCompleted }.compactMap { $0.sticker }
        
        let kodUstasiSet = Set(["laptopcomputer", "chevron.left.forwardslash.chevron.right", "cpu", "keyboard.fill"])
        if completedStickers.contains(where: { kodUstasiSet.contains($0) }) { badges.append("💻 Kod Ustası") }
        
        let patiDostuSet = Set(["cat.fill", "pawprint.fill", "dog.fill"])
        if completedStickers.contains(where: { patiDostuSet.contains($0) }) { badges.append("🐾 Pati Dostu") }
        
        let asciSet = Set(["fork.knife", "cup.and.saucer.fill", "mug.fill", "takeoutbag.and.cup.and.straw", "carrot.fill"])
        if completedStickers.contains(where: { asciSet.contains($0) }) { badges.append("🍔 Lezzet Avcısı") }
        
        let sporSet = Set(["figure.run", "dumbbell.fill", "sportscourt.fill"])
        if completedStickers.contains(where: { sporSet.contains($0) }) { badges.append("🏋️‍♀️ Sportif") }
        
        let caliskanSet = Set(["book.fill", "graduationcap.fill", "pencil.and.outline"])
        if completedStickers.contains(where: { caliskanSet.contains($0) }) { badges.append("📚 Çalışkan") }
        
        let geceKusuSet = Set(["moon.fill", "moon.stars.fill"])
        if completedStickers.contains(where: { geceKusuSet.contains($0) }) { badges.append("🌙 Gece Kuşu") }
        
        if badges.isEmpty { badges.append("🌱 Yeni Başlayan") }
        
        return badges
    }
    
    var body: some View {
        VStack(spacing: 24) {
            RoundedRectangle(cornerRadius: 3).fill(darkPink.opacity(0.2)).frame(width: 40, height: 5).padding(.top, 12)
            
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                        if let uiImage = UIImage(data: profilePicData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                                .shadow(color: hotPink.opacity(0.3), radius: 10, x: 0, y: 5)
                                .overlay(Circle().stroke(hotPink, lineWidth: 2))
                        } else {
                            ZStack {
                                Circle().fill(cardPink).frame(width: 90, height: 90).shadow(color: hotPink.opacity(0.3), radius: 10, x: 0, y: 5)
                                Image(systemName: "camera.fill").font(.system(size: 32)).foregroundColor(hotPink)
                            }
                        }
                    }
                    .onChange(of: photoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                profilePicData = data
                            }
                        }
                    }
                    
                    if !profilePicData.isEmpty {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            profilePicData = Data()
                            photoItem = nil
                        }) {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(darkPink)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .offset(x: 5, y: -5)
                    }
                }
                
                HStack {
                    TextField("Adını Yaz...", text: $userName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(darkPink)
                        .multilineTextAlignment(.center)
                        .focused($isNameFocused)
                    
                    Button(action: {
                        isNameFocused = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.subheadline)
                            .foregroundColor(darkPink.opacity(0.8))
                            .padding(8)
                            .background(cardPink)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 40)
                
                Text("Hallederiz'in Yıldızı ✨")
                    .font(.subheadline)
                    .foregroundColor(darkPink.opacity(0.7))
            }
            .padding(.top, 10)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tamamlanan Görevler 🏆")
                            .font(.headline)
                            .foregroundColor(darkPink)
                            .padding(.horizontal, 8)
                        
                        HStack(spacing: 12) {
                            StatBox(title: "Bu Hafta", count: weeklyCount, hotPink: hotPink, darkPink: darkPink, cardPink: cardPink)
                            StatBox(title: "Bu Ay", count: monthlyCount, hotPink: hotPink, darkPink: darkPink, cardPink: cardPink)
                            StatBox(title: "Bu Yıl", count: yearlyCount, hotPink: hotPink, darkPink: darkPink, cardPink: cardPink)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Kazanılan Rozetler 🎖")
                            .font(.headline)
                            .foregroundColor(darkPink)
                            .padding(.horizontal, 8)
                        
                        let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(earnedBadges, id: \.self) { badge in
                                Text(badge)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(hotPink)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(cardPink)
                                    .cornerRadius(10)
                                    .shadow(color: hotPink.opacity(0.1), radius: 3, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .background(softPink.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }
}

struct StatBox: View {
    let title: String
    let count: Int
    let hotPink: Color
    let darkPink: Color
    let cardPink: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(darkPink.opacity(0.8))
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(hotPink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(cardPink)
        .cornerRadius(12)
        .shadow(color: hotPink.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

// MARK: - KONFETİ
struct SparkleView: View {
    @State private var animate = false
    let emojis = ["🎉", "🎊", "✨", "💖", "🌸"]
    
    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { _ in
                Text(emojis.randomElement()!)
                    .font(.title2)
                    .offset(animate ? CGSize(width: CGFloat.random(in: -120 ... 120), height: CGFloat.random(in: -30 ... 30)) : .zero)
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 1.8 : 0.01)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animate = true
            }
        }
    }
}

// MARK: - SATIR GÖRÜNÜMÜ
struct TaskRowView: View {
    let task: TaskItem
    let hotPink: Color
    let darkPink: Color
    let cardPink: Color
    let onToggle: () -> Void
    let onEdit: () -> Void
    
    @State private var localCompleted: Bool = false
    @State private var showConfetti = false

    var body: some View {
        HStack(spacing: 12) {
            
            ZStack {
                if showConfetti {
                    SparkleView().zIndex(1).allowsHitTesting(false)
                }
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if !localCompleted {
                        withAnimation(.spring()) { localCompleted = true }
                        showConfetti = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            showConfetti = false
                            onToggle()
                        }
                    } else {
                        withAnimation(.spring()) { localCompleted = false }
                        onToggle()
                    }
                }) {
                    Image(systemName: localCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .frame(width: 28, height: 28)
                        .foregroundColor(localCompleted ? hotPink : darkPink.opacity(0.5))
                        .scaleEffect(localCompleted ? 1.2 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(localCompleted, color: hotPink)
                    .foregroundColor(localCompleted ? darkPink.opacity(0.4) : darkPink)
                    .animation(.easeInOut(duration: 0.3), value: localCompleted)
                
                if let time = task.reminderTime {
                    Text("Saat: \(time)")
                        .font(.caption2)
                        .foregroundColor(darkPink.opacity(0.6))
                }
            }
            
            Spacer()
            
            if let taskSticker = task.sticker, !taskSticker.isEmpty {
                Image(systemName: taskSticker)
                    .font(.title2)
                    .foregroundColor(hotPink)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onEdit()
        }
        .onAppear {
            localCompleted = task.isCompleted
        }
        .onChange(of: task.isCompleted) { oldValue, newValue in
            localCompleted = newValue
        }
    }
}

// MARK: - EKLEME / DÜZENLEME FORMU
struct TaskFormSheet: View {
    let isEditing: Bool
    let initialTask: TaskItem?
    let selectedDate: String
    
    let hotPink: Color
    let darkPink: Color
    let cardPink: Color
    let softPink: Color
    
    let onSave: (TaskItem) -> Void
    let onCancel: () -> Void
    
    @State private var title: String = ""
    @State private var hasReminder: Bool = false
    @State private var selectedTime: Date = Date()
    @State private var selectedSticker: String = "sparkles"
    @State private var symbolSearchQuery: String = ""
    
    var filteredSymbols: [String] {
        let query = symbolSearchQuery.lowercased().trimmingCharacters(in: .whitespaces)
        if query.isEmpty { return commonSFSymbols }
        
        var results: [String] = []
        for (turkishKeyword, symbols) in turkishSFSymbols {
            if turkishKeyword.contains(query) { results.append(contentsOf: symbols) }
        }
        
        let englishResults = commonSFSymbols.filter { $0.contains(query) }
        results.append(contentsOf: englishResults)
        
        if !results.contains(query) { results.insert(query, at: 0) }
        return Array(NSOrderedSet(array: results)) as! [String]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 3).fill(darkPink.opacity(0.2)).frame(width: 40, height: 5).padding(.top, 12)
            
            if initialTask?.isRoutineTask == true {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(hotPink)
                    Text("Bu değişiklik sadece bugüne özeldir. Kalıcı olması için Rutinler sayfasını kullanın.")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(darkPink)
                }
                .padding(12)
                .background(cardPink)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            Text(isEditing ? "Görevi Güncelle 🎀" : "Yeni Görev Ekle ✨")
                .font(.headline)
                .foregroundColor(darkPink)
            
            TextField("", text: $title, prompt: Text("Ne halledilecek?...").foregroundColor(darkPink.opacity(0.5)))
                .padding(14)
                .background(cardPink)
                .cornerRadius(14)
                .foregroundColor(darkPink)
                .padding(.horizontal)
                .contentShape(Rectangle())
                .onChange(of: title) { _, _ in UIImpactFeedbackGenerator(style: .light).impactOccurred() }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Çıkartma Seç")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(darkPink)
                    .padding(.horizontal)
                
                TextField("", text: $symbolSearchQuery, prompt: Text("Çıkartma ara...").foregroundColor(darkPink.opacity(0.5)))
                    .padding(10)
                    .background(cardPink)
                    .cornerRadius(10)
                    .foregroundColor(darkPink)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .onChange(of: symbolSearchQuery) { _, _ in UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filteredSymbols, id: \.self) { symbol in
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedSticker = symbol
                            }) {
                                Image(systemName: symbol)
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(darkPink)
                                    .background(selectedSticker == symbol ? hotPink.opacity(0.2) : cardPink)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(hotPink, lineWidth: selectedSticker == symbol ? 2 : 0)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                }
            }
            
            VStack(spacing: 12) {
                Toggle(isOn: $hasReminder.animation(.easeInOut)) {
                    Text("Anımsatıcı ekle ⏰")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(darkPink)
                }
                .toggleStyle(SwitchToggleStyle(tint: hotPink))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(cardPink)
                .cornerRadius(12)
                .padding(.horizontal)
                
                if hasReminder {
                    HStack {
                        Text("Saati Seç:")
                            .font(.subheadline)
                            .foregroundColor(darkPink)
                        Spacer()
                        DatePicker("Saat", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(hotPink)
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            Spacer()
            
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                
                var formattedTime: String? = nil
                if hasReminder {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    formattedTime = formatter.string(from: selectedTime)
                }
                
                let finalTask = TaskItem(
                    id: initialTask?.id ?? UUID(),
                    title: title,
                    isCompleted: initialTask?.isCompleted ?? false,
                    dateString: initialTask?.dateString ?? selectedDate,
                    reminderTime: formattedTime,
                    sticker: selectedSticker,
                    isRoutineTask: initialTask?.isRoutineTask ?? false,
                    routineID: initialTask?.routineID,
                    isManuallyAdded: initialTask?.isManuallyAdded ?? false,
                    routineTaskID: initialTask?.routineTaskID // Kilit burası
                )
                
                onSave(finalTask)
            }) {
                Text(isEditing ? "Değişiklikleri Kaydet 💅" : "Hemen Halledelim! 🚀")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(hotPink)
                    .cornerRadius(16)
                    .shadow(color: hotPink.opacity(0.4), radius: 5, x: 0, y: 3)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(softPink.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .onAppear {
            if let task = initialTask {
                title = task.title
                if let s = task.sticker { selectedSticker = s }
                if let t = task.reminderTime {
                    hasReminder = true
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    if let parsedDate = formatter.date(from: t) { selectedTime = parsedDate }
                } else {
                    hasReminder = false
                }
            } else {
                title = ""
                selectedSticker = "sparkles"
                hasReminder = false
                selectedTime = Date()
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    ContentView()
}
