//
//  ExerciseLibraryViewModel.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

final class ExerciseLibraryViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadAllExercises()
        seedDefaultExercisesIfNeeded()
    }
    
    func loadAllExercises() {
        guard let modelContext = modelContext else { return }
        
        isLoading = true
        
        let descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            let fetchedExercises = try modelContext.fetch(descriptor)
            exercises = fetchedExercises.sorted { exercise1, exercise2 in
                if exercise1.category == exercise2.category {
                    return exercise1.name < exercise2.name
                }
                return exercise1.category < exercise2.category
            }
        } catch {
            print("Error loading exercises: \(error)")
            exercises = []
        }
        
        isLoading = false
    }
    
    func addCustomExercise(
        name: String,
        exerciseType: ExerciseType,
        category: String,
        equipment: [Equipment] = [],
        primaryMuscles: [String] = [],
        secondaryMuscles: [String] = [],
        instructions: ExerciseInstructions = ExerciseInstructions()
    ) {
        guard let modelContext = modelContext else { return }
        
        let exercise = Exercise(
            name: name,
            exerciseType: exerciseType,
            category: category,
            equipment: equipment,
            primaryMuscles: primaryMuscles,
            secondaryMuscles: secondaryMuscles,
            instructions: instructions,
            isCustom: true
        )
        modelContext.insert(exercise)
        
        do {
            try modelContext.save()
            loadAllExercises()
        } catch {
            print("Error adding exercise: \(error)")
        }
    }
    
    func toggleFavorite(_ exercise: Exercise) {
        guard let modelContext = modelContext else { return }
        
        exercise.isFavorite.toggle()
        
        do {
            try modelContext.save()
            loadAllExercises()
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }

    func updateCustomExercise(
        _ exercise: Exercise,
        name: String,
        exerciseType: ExerciseType,
        category: String,
        equipment: [Equipment] = [],
        primaryMuscles: [String] = [],
        secondaryMuscles: [String] = [],
        instructions: ExerciseInstructions = ExerciseInstructions()
    ) {
        guard let modelContext = modelContext,
              exercise.isCustom else { return }
        
        exercise.name = name
        exercise.exerciseType = exerciseType
        exercise.category = category
        exercise.equipment = equipment
        exercise.primaryMuscles = primaryMuscles
        exercise.secondaryMuscles = secondaryMuscles
        exercise.setInstructions(instructions)
        
        do {
            try modelContext.save()
            loadAllExercises()
        } catch {
            print("Error updating exercise: \(error)")
        }
    }
    
    func deleteCustomExercise(_ exercise: Exercise) {
        guard let modelContext = modelContext,
              exercise.isCustom else { return }
        
        modelContext.delete(exercise)
        
        do {
            try modelContext.save()
            loadAllExercises()
        } catch {
            print("Error deleting exercise: \(error)")
        }
    }
    
    private func seedDefaultExercisesIfNeeded() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Exercise>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        
        if count > 0 {
            // Update existing exercises with instructions if missing
            updateAllDefaultExercisesWithInstructions(modelContext: modelContext)
            return
        }
        
        // CHEST EXERCISES
        createExercise(
            name: "Barbell Bench Press",
            exerciseType: .strength,
            category: "Chest",
            equipment: [.barbell, .bench],
            primaryMuscles: ["Chest"],
            secondaryMuscles: ["Triceps", "Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Lie flat on a bench with your feet planted on the floor. Grip the barbell slightly wider than shoulder-width apart.",
                execution: "Lower the bar to your chest with control, pause briefly, then press it back up to full arm extension. Keep your core tight and maintain a slight arch in your back.",
                tips: "Keep your shoulder blades retracted throughout the movement. Don't bounce the bar off your chest."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Dumbbell Bench Press",
            exerciseType: .strength,
            category: "Chest",
            equipment: [.dumbbell, .bench],
            primaryMuscles: ["Chest"],
            secondaryMuscles: ["Triceps", "Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Lie flat on a bench holding dumbbells at chest level with your palms facing forward.",
                execution: "Press the dumbbells up until your arms are fully extended, then lower them back to the starting position with control.",
                tips: "Keep your wrists straight and maintain control throughout the movement. The range of motion is greater than with a barbell."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Incline Barbell Bench Press",
            exerciseType: .strength,
            category: "Chest",
            equipment: [.barbell, .inclineBench],
            primaryMuscles: ["Chest"],
            secondaryMuscles: ["Shoulders", "Triceps"],
            instructions: ExerciseInstructions(
                setup: "Set the bench to a 30-45 degree incline. Grip the barbell slightly wider than shoulder-width apart.",
                execution: "Lower the bar to your upper chest, pause, then press it back up to full extension.",
                tips: "Focus on the upper portion of your chest. Keep your feet flat on the floor for stability."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Incline Dumbbell Press",
            exerciseType: .strength,
            category: "Chest",
            equipment: [.dumbbell, .inclineBench],
            primaryMuscles: ["Chest"],
            secondaryMuscles: ["Shoulders", "Triceps"],
            instructions: ExerciseInstructions(
                setup: "Set the bench to a 30-45 degree incline. Hold dumbbells at chest level with palms facing forward.",
                execution: "Press the dumbbells up and slightly forward until your arms are fully extended, then lower with control.",
                tips: "Use a controlled tempo and focus on squeezing your chest at the top of the movement."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Decline Bench Press",
            exerciseType: .strength,
            category: "Chest",
            equipment: [.barbell, .declineBench],
            primaryMuscles: ["Chest"],
            secondaryMuscles: ["Triceps", "Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Secure yourself on a decline bench with your feet strapped in. Grip the barbell slightly wider than shoulder-width.",
                execution: "Lower the bar to your lower chest, pause, then press it back up to full extension.",
                tips: "This targets the lower portion of your chest. Keep your core engaged throughout."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Dumbbell Flyes",
            exerciseType: .strength,
            category: "Chest",
            equipment: [.dumbbell, .bench],
            primaryMuscles: ["Chest"],
            secondaryMuscles: ["Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Lie flat on a bench holding dumbbells above your chest with a slight bend in your elbows.",
                execution: "Lower the dumbbells in a wide arc until you feel a stretch in your chest, then bring them back together above your chest.",
                tips: "Keep a slight bend in your elbows throughout. Don't go too low to avoid shoulder strain."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Cable Crossover",
            exerciseType: .strength,
            category: "Chest",
            equipment: [.cable],
            primaryMuscles: ["Chest"],
            secondaryMuscles: ["Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Stand between two cable machines with handles at shoulder height. Grab one handle in each hand with your arms slightly bent.",
                execution: "Bring your hands together in front of your chest in a wide arc, squeezing your chest muscles, then return to the starting position.",
                tips: "Keep a slight forward lean and maintain tension throughout the movement. Focus on squeezing your chest at the peak contraction."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Push-Ups",
            exerciseType: .strength,
            category: "Chest",
            equipment: [.bodyweight],
            primaryMuscles: ["Chest"],
            secondaryMuscles: ["Triceps", "Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Start in a plank position with your hands slightly wider than shoulder-width apart and your body in a straight line.",
                execution: "Lower your body until your chest nearly touches the floor, then push back up to the starting position.",
                tips: "Keep your core tight and your body in a straight line. Don't let your hips sag or rise."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Chest Dips",
            exerciseType: .strength,
            category: "Chest",
            equipment: [.dipBars],
            primaryMuscles: ["Chest"],
            secondaryMuscles: ["Triceps", "Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Grip the parallel bars and support your body weight with your arms fully extended. Lean forward slightly.",
                execution: "Lower your body by bending your elbows until you feel a stretch in your chest, then push back up to the starting position.",
                tips: "Leaning forward targets the chest more. Keep your core engaged and avoid swinging."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Machine Chest Press",
            exerciseType: .strength,
            category: "Chest",
            equipment: [.machine],
            primaryMuscles: ["Chest"],
            secondaryMuscles: ["Triceps", "Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Sit in the machine with your back flat against the pad. Grip the handles at chest level.",
                execution: "Press the handles forward until your arms are fully extended, then return to the starting position with control.",
                tips: "Adjust the seat height so the handles align with your chest. Keep your core engaged throughout."
            ),
            modelContext: modelContext
        )
        
        // BACK EXERCISES
        createExercise(
            name: "Deadlift",
            exerciseType: .strength,
            category: "Back",
            equipment: [.barbell],
            primaryMuscles: ["Back"],
            secondaryMuscles: ["Glutes", "Hamstrings", "Quadriceps"],
            instructions: ExerciseInstructions(
                setup: "Stand with your feet hip-width apart, the barbell over the middle of your feet. Grip the bar just outside your legs with a mixed or overhand grip.",
                execution: "Keep your back straight and chest up as you drive through your heels to lift the bar. Stand tall at the top, then lower the bar with control.",
                tips: "Keep the bar close to your body throughout the lift. Engage your core and maintain a neutral spine."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Barbell Rows",
            exerciseType: .strength,
            category: "Back",
            equipment: [.barbell],
            primaryMuscles: ["Back"],
            secondaryMuscles: ["Biceps", "Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Stand with feet hip-width apart, holding a barbell with an overhand grip. Hinge at the hips, keeping your back straight and core engaged.",
                execution: "Pull the bar to your lower chest/upper abdomen, squeezing your shoulder blades together, then lower with control.",
                tips: "Keep your back straight and avoid using momentum. Focus on pulling with your back muscles, not just your arms."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Dumbbell Rows",
            exerciseType: .strength,
            category: "Back",
            equipment: [.dumbbell],
            primaryMuscles: ["Back"],
            secondaryMuscles: ["Biceps", "Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Place one knee and hand on a bench, holding a dumbbell in the other hand. Keep your back straight and core engaged.",
                execution: "Pull the dumbbell up to your side, squeezing your back muscles, then lower with control.",
                tips: "Keep your torso stable and avoid rotating. Focus on pulling with your back, not just your arm."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Pull-Ups",
            exerciseType: .strength,
            category: "Back",
            equipment: [.pullupBar],
            primaryMuscles: ["Back"],
            secondaryMuscles: ["Biceps", "Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Hang from a pull-up bar with an overhand grip slightly wider than shoulder-width. Engage your core and keep your legs straight.",
                execution: "Pull your body up until your chin clears the bar, then lower yourself with control to full arm extension.",
                tips: "Avoid swinging or using momentum. Focus on pulling with your back muscles, not just your arms."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Chin-Ups",
            exerciseType: .strength,
            category: "Back",
            equipment: [.pullupBar],
            primaryMuscles: ["Back"],
            secondaryMuscles: ["Biceps"],
            instructions: ExerciseInstructions(
                setup: "Hang from a pull-up bar with an underhand grip at shoulder-width. Engage your core and keep your legs straight.",
                execution: "Pull your body up until your chin clears the bar, then lower yourself with control to full arm extension.",
                tips: "The underhand grip emphasizes the biceps more than pull-ups. Keep your body straight and avoid swinging."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Lat Pulldown",
            exerciseType: .strength,
            category: "Back",
            equipment: [.cable, .machine],
            primaryMuscles: ["Back"],
            secondaryMuscles: ["Biceps", "Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Sit at the lat pulldown machine with your thighs secured. Grip the bar wider than shoulder-width with an overhand grip.",
                execution: "Pull the bar down to your upper chest, squeezing your lats, then return to the starting position with control.",
                tips: "Keep your torso upright and avoid leaning back excessively. Focus on pulling with your back, not your arms."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Seated Cable Row",
            exerciseType: .strength,
            category: "Back",
            equipment: [.cable],
            primaryMuscles: ["Back"],
            secondaryMuscles: ["Biceps", "Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Sit at the cable row machine with your feet on the platform. Grip the handle with both hands, keeping your back straight.",
                execution: "Pull the handle to your lower chest/upper abdomen, squeezing your shoulder blades together, then return with control.",
                tips: "Keep your core engaged and avoid rounding your back. Focus on squeezing your back muscles at the peak contraction."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "T-Bar Row",
            exerciseType: .strength,
            category: "Back",
            equipment: [.barbell],
            primaryMuscles: ["Back"],
            secondaryMuscles: ["Biceps", "Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Straddle a loaded barbell with one end secured. Grip the bar with both hands, keeping your back straight and core engaged.",
                execution: "Pull the bar to your chest, squeezing your back muscles, then lower with control.",
                tips: "Keep your torso stable and avoid using momentum. This exercise allows for heavy loading."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Face Pulls",
            exerciseType: .strength,
            category: "Back",
            equipment: [.cable],
            primaryMuscles: ["Back"],
            secondaryMuscles: ["Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Attach a rope handle to a cable machine at face height. Grip the rope with both hands, palms facing each other.",
                execution: "Pull the rope toward your face, separating your hands as you pull, then return to the starting position.",
                tips: "Keep your elbows high and focus on pulling with your rear delts and upper back. This is great for posture."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Shrugs",
            exerciseType: .strength,
            category: "Back",
            equipment: [.barbell, .dumbbell],
            primaryMuscles: ["Back"],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Stand holding a barbell or dumbbells at your sides with your arms straight. Keep your back straight and core engaged.",
                execution: "Lift your shoulders up toward your ears as high as possible, hold for a moment, then lower with control.",
                tips: "Avoid rolling your shoulders. Focus on a straight up-and-down movement to target the traps effectively."
            ),
            modelContext: modelContext
        )
        
        // SHOULDERS EXERCISES
        createExercise(
            name: "Overhead Press",
            exerciseType: .strength,
            category: "Shoulders",
            equipment: [.barbell],
            primaryMuscles: ["Shoulders"],
            secondaryMuscles: ["Triceps", "Core"],
            instructions: ExerciseInstructions(
                setup: "Stand with feet hip-width apart, holding a barbell at shoulder height with an overhand grip slightly wider than shoulder-width.",
                execution: "Press the bar straight up until your arms are fully extended overhead, then lower with control back to shoulder height.",
                tips: "Keep your core tight and avoid arching your back excessively. Press straight up, not forward."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Dumbbell Shoulder Press",
            exerciseType: .strength,
            category: "Shoulders",
            equipment: [.dumbbell],
            primaryMuscles: ["Shoulders"],
            secondaryMuscles: ["Triceps", "Core"],
            instructions: ExerciseInstructions(
                setup: "Sit or stand holding dumbbells at shoulder height with your palms facing forward and elbows slightly forward.",
                execution: "Press the dumbbells straight up until your arms are fully extended, then lower with control back to shoulder height.",
                tips: "Keep your core engaged and maintain control throughout. The range of motion is greater than with a barbell."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Arnold Press",
            exerciseType: .strength,
            category: "Shoulders",
            equipment: [.dumbbell],
            primaryMuscles: ["Shoulders"],
            secondaryMuscles: ["Triceps"],
            instructions: ExerciseInstructions(
                setup: "Sit or stand holding dumbbells at shoulder height with your palms facing you (supinated grip).",
                execution: "Press the dumbbells up while rotating your wrists so your palms face forward at the top, then reverse the motion as you lower.",
                tips: "The rotation adds extra shoulder work. Keep your core engaged and maintain control throughout the movement."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Lateral Raises",
            exerciseType: .strength,
            category: "Shoulders",
            equipment: [.dumbbell, .cable],
            primaryMuscles: ["Shoulders"],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Stand holding dumbbells at your sides with a slight bend in your elbows. Keep your core engaged and back straight.",
                execution: "Raise your arms out to the sides until they're parallel to the floor, then lower with control back to the starting position.",
                tips: "Keep a slight bend in your elbows and avoid swinging. Focus on lifting with your shoulders, not momentum."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Front Raises",
            exerciseType: .strength,
            category: "Shoulders",
            equipment: [.dumbbell],
            primaryMuscles: ["Shoulders"],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Stand holding dumbbells in front of your thighs with your palms facing your body. Keep your core engaged.",
                execution: "Raise the dumbbells forward and up until they're at shoulder height, then lower with control.",
                tips: "Keep a slight bend in your elbows and avoid swinging. Focus on the front deltoids."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Reverse Flyes",
            exerciseType: .strength,
            category: "Shoulders",
            equipment: [.dumbbell, .cable],
            primaryMuscles: ["Shoulders"],
            secondaryMuscles: ["Back"],
            instructions: ExerciseInstructions(
                setup: "Stand with a slight forward lean, holding dumbbells with your arms slightly bent. Keep your core engaged.",
                execution: "Raise your arms out to the sides in a wide arc, squeezing your rear delts, then lower with control.",
                tips: "Keep a slight bend in your elbows throughout. Focus on squeezing your rear deltoids at the peak."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Upright Rows",
            exerciseType: .strength,
            category: "Shoulders",
            equipment: [.barbell, .dumbbell],
            primaryMuscles: ["Shoulders"],
            secondaryMuscles: ["Back"],
            instructions: ExerciseInstructions(
                setup: "Stand holding a barbell or dumbbells in front of your thighs with an overhand grip slightly narrower than shoulder-width.",
                execution: "Pull the weight up along your body to chest height, leading with your elbows, then lower with control.",
                tips: "Keep the weight close to your body. Avoid going too high to prevent shoulder impingement."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Machine Shoulder Press",
            exerciseType: .strength,
            category: "Shoulders",
            equipment: [.machine],
            primaryMuscles: ["Shoulders"],
            secondaryMuscles: ["Triceps"],
            instructions: ExerciseInstructions(
                setup: "Sit in the machine with your back flat against the pad. Grip the handles at shoulder height.",
                execution: "Press the handles up until your arms are fully extended, then return to the starting position with control.",
                tips: "Adjust the seat height so the handles align with your shoulders. Keep your core engaged throughout."
            ),
            modelContext: modelContext
        )
        
        // ARMS EXERCISES
        createExercise(
            name: "Barbell Bicep Curl",
            exerciseType: .strength,
            category: "Arms",
            equipment: [.barbell],
            primaryMuscles: ["Biceps"],
            secondaryMuscles: ["Forearms"],
            instructions: ExerciseInstructions(
                setup: "Stand holding a barbell with an underhand grip at shoulder-width. Keep your elbows close to your body and core engaged.",
                execution: "Curl the bar up toward your shoulders, squeezing your biceps, then lower with control back to the starting position.",
                tips: "Keep your elbows stationary and avoid swinging. Focus on the bicep contraction at the top."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Dumbbell Bicep Curl",
            exerciseType: .strength,
            category: "Arms",
            equipment: [.dumbbell],
            primaryMuscles: ["Biceps"],
            secondaryMuscles: ["Forearms"],
            instructions: ExerciseInstructions(
                setup: "Stand holding dumbbells at your sides with an underhand grip. Keep your elbows close to your body and core engaged.",
                execution: "Curl the dumbbells up toward your shoulders, squeezing your biceps, then lower with control.",
                tips: "You can curl both arms together or alternate. Keep your elbows stationary and avoid swinging."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Hammer Curls",
            exerciseType: .strength,
            category: "Arms",
            equipment: [.dumbbell],
            primaryMuscles: ["Biceps"],
            secondaryMuscles: ["Forearms"],
            instructions: ExerciseInstructions(
                setup: "Stand holding dumbbells at your sides with a neutral grip (palms facing each other). Keep your elbows close to your body.",
                execution: "Curl the dumbbells up toward your shoulders, keeping your palms facing each other, then lower with control.",
                tips: "This grip targets the brachialis and forearms more than standard curls. Keep your elbows stationary."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Preacher Curls",
            exerciseType: .strength,
            category: "Arms",
            equipment: [.ezBar, .dumbbell],
            primaryMuscles: ["Biceps"],
            secondaryMuscles: ["Forearms"],
            instructions: ExerciseInstructions(
                setup: "Sit at a preacher bench with your arms resting on the pad. Hold an EZ bar or dumbbells with an underhand grip.",
                execution: "Curl the weight up, squeezing your biceps, then lower with control until your arms are fully extended.",
                tips: "The pad isolates the biceps by preventing swinging. Focus on a controlled negative (lowering) phase."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Cable Curls",
            exerciseType: .strength,
            category: "Arms",
            equipment: [.cable],
            primaryMuscles: ["Biceps"],
            secondaryMuscles: ["Forearms"],
            instructions: ExerciseInstructions(
                setup: "Stand facing a cable machine with a handle attached at the bottom. Grip the handle with an underhand grip.",
                execution: "Curl the handle up toward your shoulders, squeezing your biceps, then lower with control.",
                tips: "Cables provide constant tension throughout the movement. Keep your elbows stationary and avoid swinging."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Tricep Pushdown",
            exerciseType: .strength,
            category: "Arms",
            equipment: [.cable],
            primaryMuscles: ["Triceps"],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Stand facing a cable machine with a handle attached at the top. Grip the handle with an overhand grip, elbows at your sides.",
                execution: "Push the handle down until your arms are fully extended, squeezing your triceps, then return with control.",
                tips: "Keep your elbows close to your body and avoid swinging. Focus on the tricep contraction at the bottom."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Overhead Tricep Extension",
            exerciseType: .strength,
            category: "Arms",
            equipment: [.dumbbell, .cable],
            primaryMuscles: ["Triceps"],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Stand or sit holding a dumbbell or cable handle overhead with both hands, elbows pointing forward.",
                execution: "Lower the weight behind your head by bending your elbows, then extend back up to the starting position.",
                tips: "Keep your elbows pointing forward and avoid flaring them out. Focus on the tricep stretch and contraction."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Skull Crushers",
            exerciseType: .strength,
            category: "Arms",
            equipment: [.ezBar, .barbell],
            primaryMuscles: ["Triceps"],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Lie on a bench holding an EZ bar or barbell above your chest with your arms extended and elbows pointing forward.",
                execution: "Lower the weight toward your forehead by bending your elbows, then extend back up to the starting position.",
                tips: "Keep your elbows stationary and pointing forward. Don't let the weight touch your head - stop just above."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Tricep Dips",
            exerciseType: .strength,
            category: "Arms",
            equipment: [.dipBars, .bench],
            primaryMuscles: ["Triceps"],
            secondaryMuscles: ["Shoulders", "Chest"],
            instructions: ExerciseInstructions(
                setup: "Grip parallel bars or a bench edge with your hands, supporting your body weight with your arms extended.",
                execution: "Lower your body by bending your elbows until you feel a stretch in your triceps, then push back up.",
                tips: "Keep your body upright to target triceps more. Avoid going too low to prevent shoulder strain."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Close-Grip Bench Press",
            exerciseType: .strength,
            category: "Arms",
            equipment: [.barbell, .bench],
            primaryMuscles: ["Triceps"],
            secondaryMuscles: ["Chest", "Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Lie on a bench with your hands closer than shoulder-width apart on the barbell. Keep your elbows close to your body.",
                execution: "Lower the bar to your chest, then press it back up, focusing on using your triceps.",
                tips: "The close grip shifts emphasis to the triceps. Keep your elbows close to your body throughout."
            ),
            modelContext: modelContext
        )
        
        // LEGS EXERCISES
        createExercise(
            name: "Barbell Squat",
            exerciseType: .strength,
            category: "Legs",
            equipment: [.barbell],
            primaryMuscles: ["Quadriceps", "Glutes"],
            secondaryMuscles: ["Hamstrings", "Core"],
            instructions: ExerciseInstructions(
                setup: "Stand with the barbell across your upper back, feet shoulder-width apart. Keep your chest up and core engaged.",
                execution: "Lower your body by bending your knees and hips until your thighs are parallel to the floor, then drive back up through your heels.",
                tips: "Keep your knees tracking over your toes. Maintain a neutral spine and don't let your knees cave inward."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Front Squat",
            exerciseType: .strength,
            category: "Legs",
            equipment: [.barbell],
            primaryMuscles: ["Quadriceps"],
            secondaryMuscles: ["Glutes", "Core"],
            instructions: ExerciseInstructions(
                setup: "Stand with the barbell across your front shoulders, holding it with a clean grip or crossed arms. Keep your elbows up.",
                execution: "Lower your body by bending your knees and hips until your thighs are parallel to the floor, then drive back up.",
                tips: "Keep your torso upright and elbows high. This targets the quads more than back squats."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Goblet Squat",
            exerciseType: .strength,
            category: "Legs",
            equipment: [.dumbbell, .kettlebell],
            primaryMuscles: ["Quadriceps", "Glutes"],
            secondaryMuscles: ["Core"],
            instructions: ExerciseInstructions(
                setup: "Hold a dumbbell or kettlebell at chest height with both hands. Stand with feet shoulder-width apart.",
                execution: "Lower your body by bending your knees and hips until your thighs are parallel to the floor, then drive back up.",
                tips: "Keep your torso upright and the weight close to your chest. Great for learning proper squat form."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Leg Press",
            exerciseType: .strength,
            category: "Legs",
            equipment: [.machine],
            primaryMuscles: ["Quadriceps", "Glutes"],
            secondaryMuscles: ["Hamstrings"],
            instructions: ExerciseInstructions(
                setup: "Sit in the leg press machine with your feet shoulder-width apart on the platform. Keep your back flat against the pad.",
                execution: "Lower the platform by bending your knees until they form a 90-degree angle, then press back up to full extension.",
                tips: "Keep your knees tracking over your toes. Don't lock your knees at the top. Lower with control."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Romanian Deadlift",
            exerciseType: .strength,
            category: "Legs",
            equipment: [.barbell, .dumbbell],
            primaryMuscles: ["Hamstrings", "Glutes"],
            secondaryMuscles: ["Back"],
            instructions: ExerciseInstructions(
                setup: "Stand holding a barbell or dumbbells in front of your thighs. Keep your back straight and core engaged.",
                execution: "Hinge at your hips, lowering the weight while keeping your legs relatively straight, then return to standing.",
                tips: "Keep your back straight and feel the stretch in your hamstrings. Don't round your back."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Leg Curl",
            exerciseType: .strength,
            category: "Legs",
            equipment: [.machine],
            primaryMuscles: ["Hamstrings"],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Lie face down on the leg curl machine with your ankles under the pad. Keep your torso flat on the bench.",
                execution: "Curl your heels toward your glutes by bending your knees, squeezing your hamstrings, then lower with control.",
                tips: "Keep your hips down on the bench. Focus on the hamstring contraction at the peak of the movement."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Leg Extension",
            exerciseType: .strength,
            category: "Legs",
            equipment: [.machine],
            primaryMuscles: ["Quadriceps"],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Sit in the leg extension machine with your shins against the pad. Keep your back flat against the seat.",
                execution: "Extend your legs until they're straight, squeezing your quads, then lower with control back to the starting position.",
                tips: "Keep your back against the seat and avoid swinging. Control the negative (lowering) phase."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Walking Lunges",
            exerciseType: .strength,
            category: "Legs",
            equipment: [.dumbbell, .bodyweight],
            primaryMuscles: ["Quadriceps", "Glutes"],
            secondaryMuscles: ["Hamstrings", "Core"],
            instructions: ExerciseInstructions(
                setup: "Stand holding dumbbells at your sides or with just bodyweight. Take a step forward into a lunge position.",
                execution: "Lower your back knee toward the ground, then push through your front heel to step forward into the next lunge.",
                tips: "Keep your front knee over your ankle and your torso upright. Alternate legs as you walk forward."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Bulgarian Split Squat",
            exerciseType: .strength,
            category: "Legs",
            equipment: [.dumbbell],
            primaryMuscles: ["Quadriceps", "Glutes"],
            secondaryMuscles: ["Core"],
            instructions: ExerciseInstructions(
                setup: "Place your back foot on a bench behind you, holding a dumbbell in each hand. Keep your front foot flat on the ground.",
                execution: "Lower your body by bending your front knee until your thigh is parallel to the floor, then drive back up.",
                tips: "Keep your front knee tracking over your ankle. This is a single-leg exercise, so it's more challenging."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Calf Raises",
            exerciseType: .strength,
            category: "Legs",
            equipment: [.machine, .bodyweight],
            primaryMuscles: ["Calves"],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Stand on a platform or flat ground with the balls of your feet on the edge. Hold weights or use bodyweight.",
                execution: "Raise up onto your toes as high as possible, squeezing your calves, then lower with control.",
                tips: "Keep your legs straight for gastrocnemius, or bend your knees slightly for soleus. Control the full range of motion."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Hip Thrust",
            exerciseType: .strength,
            category: "Legs",
            equipment: [.barbell],
            primaryMuscles: ["Glutes"],
            secondaryMuscles: ["Hamstrings", "Core"],
            instructions: ExerciseInstructions(
                setup: "Sit on the ground with your upper back against a bench, a barbell across your hips. Your feet should be flat on the floor.",
                execution: "Drive through your heels to lift your hips up, squeezing your glutes at the top, then lower with control.",
                tips: "Keep your chin tucked and core engaged. Focus on squeezing your glutes at the peak of the movement."
            ),
            modelContext: modelContext
        )
        
        // CORE EXERCISES
        createExercise(
            name: "Plank",
            exerciseType: .strength,
            category: "Core",
            equipment: [.bodyweight],
            primaryMuscles: ["Abs", "Core"],
            secondaryMuscles: ["Shoulders", "Back"],
            instructions: ExerciseInstructions(
                setup: "Start in a push-up position with your forearms on the ground, elbows under your shoulders. Keep your body in a straight line.",
                execution: "Hold this position, keeping your core tight and body straight. Don't let your hips sag or rise.",
                tips: "Keep your head in line with your spine. Focus on breathing normally while maintaining the position."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Ab Rollout",
            exerciseType: .strength,
            category: "Core",
            equipment: [.bodyweight],
            primaryMuscles: ["Abs", "Core"],
            secondaryMuscles: ["Shoulders", "Back"],
            instructions: ExerciseInstructions(
                setup: "Kneel on the ground holding an ab wheel or barbell with plates. Keep your core engaged and back straight.",
                execution: "Roll forward by extending your arms and hips, keeping your core tight, then roll back to the starting position.",
                tips: "Don't let your lower back arch excessively. Only go as far as you can maintain proper form."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Hanging Leg Raises",
            exerciseType: .strength,
            category: "Core",
            equipment: [.pullupBar],
            primaryMuscles: ["Abs", "Core"],
            secondaryMuscles: ["Hip Flexors"],
            instructions: ExerciseInstructions(
                setup: "Hang from a pull-up bar with your arms fully extended. Keep your core engaged and legs straight or slightly bent.",
                execution: "Raise your legs up toward your chest, squeezing your abs, then lower with control back to the starting position.",
                tips: "Avoid swinging. Focus on using your abs to lift your legs, not momentum. You can bend your knees to make it easier."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Cable Crunches",
            exerciseType: .strength,
            category: "Core",
            equipment: [.cable],
            primaryMuscles: ["Abs"],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Kneel facing a cable machine with a rope handle attached at the top. Hold the rope behind your head.",
                execution: "Curl your torso down, bringing your elbows toward your knees, squeezing your abs, then return to the starting position.",
                tips: "Keep your hips stationary and focus on crunching your abs, not pulling with your arms."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Russian Twists",
            exerciseType: .strength,
            category: "Core",
            equipment: [.bodyweight, .dumbbell],
            primaryMuscles: ["Abs", "Obliques"],
            secondaryMuscles: ["Core"],
            instructions: ExerciseInstructions(
                setup: "Sit on the ground with your knees bent and feet elevated. Hold a weight or use bodyweight, lean back slightly.",
                execution: "Rotate your torso from side to side, bringing the weight or your hands to each side, keeping your core engaged.",
                tips: "Keep your back straight and avoid rounding. Focus on rotating with your core, not just your arms."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Dead Bug",
            exerciseType: .strength,
            category: "Core",
            equipment: [.bodyweight],
            primaryMuscles: ["Abs", "Core"],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Lie on your back with your arms extended toward the ceiling and knees bent at 90 degrees.",
                execution: "Lower your opposite arm and leg toward the ground while keeping your core engaged, then return and alternate sides.",
                tips: "Keep your lower back pressed to the ground. Move slowly and focus on core stability."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Bird Dog",
            exerciseType: .strength,
            category: "Core",
            equipment: [.bodyweight],
            primaryMuscles: ["Core", "Back"],
            secondaryMuscles: ["Glutes", "Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Start on your hands and knees with your hands under your shoulders and knees under your hips.",
                execution: "Extend your opposite arm and leg straight out, keeping your core engaged and back straight, then return and alternate.",
                tips: "Keep your hips level and avoid rotating. Focus on stability and control throughout the movement."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Side Plank",
            exerciseType: .strength,
            category: "Core",
            equipment: [.bodyweight],
            primaryMuscles: ["Obliques", "Core"],
            secondaryMuscles: ["Shoulders"],
            instructions: ExerciseInstructions(
                setup: "Lie on your side with your forearm on the ground, elbow under your shoulder. Stack your feet and keep your body straight.",
                execution: "Lift your hips off the ground, forming a straight line from head to feet, and hold the position.",
                tips: "Keep your body in a straight line and avoid sagging. You can modify by bending your bottom knee."
            ),
            modelContext: modelContext
        )
        
        // CARDIO EXERCISES
        createExercise(
            name: "Outdoor Run",
            exerciseType: .cardio,
            category: "Running",
            equipment: [.none],
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Wear appropriate running shoes and choose a safe route. Start with a light warm-up walk.",
                execution: "Run at a pace that allows you to maintain conversation. Focus on steady breathing and good running form.",
                tips: "Land on the middle of your foot, not your heel. Keep your posture upright and arms relaxed."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Treadmill Run",
            exerciseType: .cardio,
            category: "Running",
            equipment: [.treadmill],
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Set the treadmill to your desired speed and incline. Start with a warm-up walk.",
                execution: "Run at a steady pace, maintaining good form. Adjust speed and incline as needed.",
                tips: "Don't hold onto the handrails - let your arms swing naturally. Match the belt speed with your stride."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Interval Sprints",
            exerciseType: .cardio,
            category: "Running",
            equipment: [.none, .treadmill],
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Warm up with light jogging. Choose a track, trail, or treadmill for your intervals.",
                execution: "Sprint at maximum effort for a set time or distance, then recover with walking or light jogging. Repeat.",
                tips: "Start with shorter intervals and longer recovery periods. Gradually increase intensity as you build fitness."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Outdoor Walk",
            exerciseType: .cardio,
            category: "Walking",
            equipment: [.none],
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Wear comfortable walking shoes. Choose a safe route with good footing.",
                execution: "Walk at a brisk pace that elevates your heart rate but allows you to maintain conversation.",
                tips: "Maintain good posture with your head up and shoulders back. Swing your arms naturally."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Treadmill Walk",
            exerciseType: .cardio,
            category: "Walking",
            equipment: [.treadmill],
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Set the treadmill to a comfortable walking speed and incline. Start with a flat surface.",
                execution: "Walk at a steady pace, maintaining good posture. You can increase incline for more intensity.",
                tips: "Don't hold onto the handrails - let your arms swing naturally. Increase speed or incline gradually."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Incline Walk",
            exerciseType: .cardio,
            category: "Walking",
            equipment: [.treadmill],
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Set the treadmill to a comfortable walking speed with an elevated incline (5-15%).",
                execution: "Walk at a steady pace up the incline, maintaining good posture and engaging your glutes and calves.",
                tips: "Start with a lower incline and gradually increase. This is great for building lower body strength."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Outdoor Cycling",
            exerciseType: .cardio,
            category: "Cycling",
            equipment: [.bike],
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Ensure your bike is properly adjusted and you're wearing a helmet. Choose a safe route.",
                execution: "Pedal at a steady cadence, maintaining good form. Adjust your pace based on terrain and fitness level.",
                tips: "Keep your core engaged and maintain a smooth pedaling motion. Shift gears appropriately for hills."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Stationary Bike",
            exerciseType: .cardio,
            category: "Cycling",
            equipment: [.bike],
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Adjust the seat height so your leg is almost fully extended at the bottom of the pedal stroke.",
                execution: "Pedal at a steady cadence, adjusting resistance as needed. Maintain good posture throughout.",
                tips: "Keep your core engaged and avoid slouching. You can do intervals by varying resistance and speed."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Spin Class",
            exerciseType: .cardio,
            category: "Cycling",
            equipment: [.bike],
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Adjust your bike seat and handlebars to proper height. Follow the instructor's guidance for setup.",
                execution: "Follow the class format, which typically includes warm-up, intervals, and cool-down phases.",
                tips: "Listen to your body and adjust resistance as needed. Stay hydrated and maintain good form throughout."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Rowing Machine",
            exerciseType: .cardio,
            category: "Rowing",
            equipment: [.rowingMachine],
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Sit on the rower with your feet secured in the straps. Grip the handle with an overhand grip.",
                execution: "Drive with your legs, then lean back slightly and pull the handle to your chest, then reverse the motion.",
                tips: "The sequence is legs, then core, then arms. Return in reverse order. Keep your back straight."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Stair Climber",
            exerciseType: .cardio,
            category: "Stair Climber",
            equipment: [.stairClimber],
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Step onto the machine and select your desired speed and resistance level.",
                execution: "Climb at a steady pace, maintaining good posture. Keep your core engaged and avoid leaning on the handrails.",
                tips: "Use the handrails for balance only, not to support your weight. Focus on pushing through your heels."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Stadium Stairs",
            exerciseType: .cardio,
            category: "Stair Climber",
            equipment: [.none],
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Find a set of stadium stairs or a tall staircase. Warm up with light walking.",
                execution: "Climb the stairs at a brisk pace, using every step or every other step. Walk down for recovery.",
                tips: "Maintain good posture and use the handrail if needed for safety. Start with shorter sessions and build up."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Jump Rope",
            exerciseType: .cardio,
            category: "Jump Rope",
            equipment: [.jumpRope],
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Hold the rope handles at your sides with the rope behind you. Stand with feet together and knees slightly bent.",
                execution: "Jump over the rope as it passes under your feet, landing on the balls of your feet. Maintain a steady rhythm.",
                tips: "Keep your elbows close to your body and rotate with your wrists, not your arms. Start slow and build speed."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Elliptical",
            exerciseType: .cardio,
            category: "Other",
            equipment: [.elliptical],
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Step onto the elliptical and select your desired resistance and incline level.",
                execution: "Move your legs in a smooth elliptical motion, maintaining good posture. Use the moving handles for upper body engagement.",
                tips: "Keep your core engaged and avoid slouching. You can go forward or backward to target different muscles."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "Swimming",
            exerciseType: .cardio,
            category: "Swimming",
            equipment: [.none],
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Enter the pool and choose your stroke (freestyle, breaststroke, etc.). Warm up with easy laps.",
                execution: "Swim at a steady pace, focusing on good form and breathing rhythm. Rest between laps as needed.",
                tips: "Focus on smooth, efficient strokes. Breathe regularly and maintain a consistent pace."
            ),
            modelContext: modelContext
        )
        
        createExercise(
            name: "HIIT Session",
            exerciseType: .cardio,
            category: "HIIT",
            equipment: [.none],
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: ExerciseInstructions(
                setup: "Choose a combination of exercises (burpees, jumping jacks, mountain climbers, etc.). Warm up with light movement.",
                execution: "Perform each exercise at maximum effort for a set time (20-60 seconds), then rest for equal or shorter time. Repeat.",
                tips: "Maintain good form even when fatigued. Start with shorter work intervals and longer rest periods."
            ),
            modelContext: modelContext
        )
        
        do {
            try modelContext.save()
            loadAllExercises()
        } catch {
            print("Error seeding exercises: \(error)")
        }
    }
    
    private func createExercise(
        name: String,
        exerciseType: ExerciseType,
        category: String,
        equipment: [Equipment],
        primaryMuscles: [String],
        secondaryMuscles: [String],
        instructions: ExerciseInstructions,
        modelContext: ModelContext
    ) {
        let exercise = Exercise(
            name: name,
            exerciseType: exerciseType,
            category: category,
            equipment: equipment,
            primaryMuscles: primaryMuscles,
            secondaryMuscles: secondaryMuscles,
            instructions: instructions,
            isCustom: false
        )
        modelContext.insert(exercise)
    }
    
    private func updateExerciseInstructions(name: String, instructions: ExerciseInstructions, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { $0.name == name && !$0.isCustom }
        )
        
        if let exercises = try? modelContext.fetch(descriptor), let exercise = exercises.first {
            let current = exercise.getInstructions()
            let hasEmptyInstructions = current.setup.isEmpty && current.execution.isEmpty && current.tips.isEmpty
            
            if hasEmptyInstructions {
                exercise.setInstructions(instructions)
            }
        }
    }
    
    private func updateAllDefaultExercisesWithInstructions(modelContext: ModelContext) {
        // CHEST EXERCISES
        updateExerciseInstructions(name: "Barbell Bench Press", instructions: ExerciseInstructions(
            setup: "Lie flat on a bench with your feet planted on the floor. Grip the barbell slightly wider than shoulder-width apart.",
            execution: "Lower the bar to your chest with control, pause briefly, then press it back up to full arm extension. Keep your core tight and maintain a slight arch in your back.",
            tips: "Keep your shoulder blades retracted throughout the movement. Don't bounce the bar off your chest."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Dumbbell Bench Press", instructions: ExerciseInstructions(
            setup: "Lie flat on a bench holding dumbbells at chest level with your palms facing forward.",
            execution: "Press the dumbbells up until your arms are fully extended, then lower them back to the starting position with control.",
            tips: "Keep your wrists straight and maintain control throughout the movement. The range of motion is greater than with a barbell."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Incline Barbell Bench Press", instructions: ExerciseInstructions(
            setup: "Set the bench to a 30-45 degree incline. Grip the barbell slightly wider than shoulder-width apart.",
            execution: "Lower the bar to your upper chest, pause, then press it back up to full extension.",
            tips: "Focus on the upper portion of your chest. Keep your feet flat on the floor for stability."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Incline Dumbbell Press", instructions: ExerciseInstructions(
            setup: "Set the bench to a 30-45 degree incline. Hold dumbbells at chest level with palms facing forward.",
            execution: "Press the dumbbells up and slightly forward until your arms are fully extended, then lower with control.",
            tips: "Use a controlled tempo and focus on squeezing your chest at the top of the movement."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Decline Bench Press", instructions: ExerciseInstructions(
            setup: "Secure yourself on a decline bench with your feet strapped in. Grip the barbell slightly wider than shoulder-width.",
            execution: "Lower the bar to your lower chest, pause, then press it back up to full extension.",
            tips: "This targets the lower portion of your chest. Keep your core engaged throughout."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Dumbbell Flyes", instructions: ExerciseInstructions(
            setup: "Lie flat on a bench holding dumbbells above your chest with a slight bend in your elbows.",
            execution: "Lower the dumbbells in a wide arc until you feel a stretch in your chest, then bring them back together above your chest.",
            tips: "Keep a slight bend in your elbows throughout. Don't go too low to avoid shoulder strain."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Cable Crossover", instructions: ExerciseInstructions(
            setup: "Stand between two cable machines with handles at shoulder height. Grab one handle in each hand with your arms slightly bent.",
            execution: "Bring your hands together in front of your chest in a wide arc, squeezing your chest muscles, then return to the starting position.",
            tips: "Keep a slight forward lean and maintain tension throughout the movement. Focus on squeezing your chest at the peak contraction."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Push-Ups", instructions: ExerciseInstructions(
            setup: "Start in a plank position with your hands slightly wider than shoulder-width apart and your body in a straight line.",
            execution: "Lower your body until your chest nearly touches the floor, then push back up to the starting position.",
            tips: "Keep your core tight and your body in a straight line. Don't let your hips sag or rise."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Chest Dips", instructions: ExerciseInstructions(
            setup: "Grip the parallel bars and support your body weight with your arms fully extended. Lean forward slightly.",
            execution: "Lower your body by bending your elbows until you feel a stretch in your chest, then push back up to the starting position.",
            tips: "Leaning forward targets the chest more. Keep your core engaged and avoid swinging."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Machine Chest Press", instructions: ExerciseInstructions(
            setup: "Sit in the machine with your back flat against the pad. Grip the handles at chest level.",
            execution: "Press the handles forward until your arms are fully extended, then return to the starting position with control.",
            tips: "Adjust the seat height so the handles align with your chest. Keep your core engaged throughout."
        ), modelContext: modelContext)
        
        // BACK EXERCISES
        updateExerciseInstructions(name: "Deadlift", instructions: ExerciseInstructions(
            setup: "Stand with your feet hip-width apart, the barbell over the middle of your feet. Grip the bar just outside your legs with a mixed or overhand grip.",
            execution: "Keep your back straight and chest up as you drive through your heels to lift the bar. Stand tall at the top, then lower the bar with control.",
            tips: "Keep the bar close to your body throughout the lift. Engage your core and maintain a neutral spine."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Barbell Rows", instructions: ExerciseInstructions(
            setup: "Stand with feet hip-width apart, holding a barbell with an overhand grip. Hinge at the hips, keeping your back straight and core engaged.",
            execution: "Pull the bar to your lower chest/upper abdomen, squeezing your shoulder blades together, then lower with control.",
            tips: "Keep your back straight and avoid using momentum. Focus on pulling with your back muscles, not just your arms."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Dumbbell Rows", instructions: ExerciseInstructions(
            setup: "Place one knee and hand on a bench, holding a dumbbell in the other hand. Keep your back straight and core engaged.",
            execution: "Pull the dumbbell up to your side, squeezing your back muscles, then lower with control.",
            tips: "Keep your torso stable and avoid rotating. Focus on pulling with your back, not just your arm."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Pull-Ups", instructions: ExerciseInstructions(
            setup: "Hang from a pull-up bar with an overhand grip slightly wider than shoulder-width. Engage your core and keep your legs straight.",
            execution: "Pull your body up until your chin clears the bar, then lower yourself with control to full arm extension.",
            tips: "Avoid swinging or using momentum. Focus on pulling with your back muscles, not just your arms."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Chin-Ups", instructions: ExerciseInstructions(
            setup: "Hang from a pull-up bar with an underhand grip at shoulder-width. Engage your core and keep your legs straight.",
            execution: "Pull your body up until your chin clears the bar, then lower yourself with control to full arm extension.",
            tips: "The underhand grip emphasizes the biceps more than pull-ups. Keep your body straight and avoid swinging."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Lat Pulldown", instructions: ExerciseInstructions(
            setup: "Sit at the lat pulldown machine with your thighs secured. Grip the bar wider than shoulder-width with an overhand grip.",
            execution: "Pull the bar down to your upper chest, squeezing your lats, then return to the starting position with control.",
            tips: "Keep your torso upright and avoid leaning back excessively. Focus on pulling with your back, not your arms."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Seated Cable Row", instructions: ExerciseInstructions(
            setup: "Sit at the cable row machine with your feet on the platform. Grip the handle with both hands, keeping your back straight.",
            execution: "Pull the handle to your lower chest/upper abdomen, squeezing your shoulder blades together, then return with control.",
            tips: "Keep your core engaged and avoid rounding your back. Focus on squeezing your back muscles at the peak contraction."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "T-Bar Row", instructions: ExerciseInstructions(
            setup: "Straddle a loaded barbell with one end secured. Grip the bar with both hands, keeping your back straight and core engaged.",
            execution: "Pull the bar to your chest, squeezing your back muscles, then lower with control.",
            tips: "Keep your torso stable and avoid using momentum. This exercise allows for heavy loading."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Face Pulls", instructions: ExerciseInstructions(
            setup: "Attach a rope handle to a cable machine at face height. Grip the rope with both hands, palms facing each other.",
            execution: "Pull the rope toward your face, separating your hands as you pull, then return to the starting position.",
            tips: "Keep your elbows high and focus on pulling with your rear delts and upper back. This is great for posture."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Shrugs", instructions: ExerciseInstructions(
            setup: "Stand holding a barbell or dumbbells at your sides with your arms straight. Keep your back straight and core engaged.",
            execution: "Lift your shoulders up toward your ears as high as possible, hold for a moment, then lower with control.",
            tips: "Avoid rolling your shoulders. Focus on a straight up-and-down movement to target the traps effectively."
        ), modelContext: modelContext)
        
        // SHOULDERS EXERCISES
        updateExerciseInstructions(name: "Overhead Press", instructions: ExerciseInstructions(
            setup: "Stand with feet hip-width apart, holding a barbell at shoulder height with an overhand grip slightly wider than shoulder-width.",
            execution: "Press the bar straight up until your arms are fully extended overhead, then lower with control back to shoulder height.",
            tips: "Keep your core tight and avoid arching your back excessively. Press straight up, not forward."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Dumbbell Shoulder Press", instructions: ExerciseInstructions(
            setup: "Sit or stand holding dumbbells at shoulder height with your palms facing forward and elbows slightly forward.",
            execution: "Press the dumbbells straight up until your arms are fully extended, then lower with control back to shoulder height.",
            tips: "Keep your core engaged and maintain control throughout. The range of motion is greater than with a barbell."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Arnold Press", instructions: ExerciseInstructions(
            setup: "Sit or stand holding dumbbells at shoulder height with your palms facing you (supinated grip).",
            execution: "Press the dumbbells up while rotating your wrists so your palms face forward at the top, then reverse the motion as you lower.",
            tips: "The rotation adds extra shoulder work. Keep your core engaged and maintain control throughout the movement."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Lateral Raises", instructions: ExerciseInstructions(
            setup: "Stand holding dumbbells at your sides with a slight bend in your elbows. Keep your core engaged and back straight.",
            execution: "Raise your arms out to the sides until they're parallel to the floor, then lower with control back to the starting position.",
            tips: "Keep a slight bend in your elbows and avoid swinging. Focus on lifting with your shoulders, not momentum."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Front Raises", instructions: ExerciseInstructions(
            setup: "Stand holding dumbbells in front of your thighs with your palms facing your body. Keep your core engaged.",
            execution: "Raise the dumbbells forward and up until they're at shoulder height, then lower with control.",
            tips: "Keep a slight bend in your elbows and avoid swinging. Focus on the front deltoids."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Reverse Flyes", instructions: ExerciseInstructions(
            setup: "Stand with a slight forward lean, holding dumbbells with your arms slightly bent. Keep your core engaged.",
            execution: "Raise your arms out to the sides in a wide arc, squeezing your rear delts, then lower with control.",
            tips: "Keep a slight bend in your elbows throughout. Focus on squeezing your rear deltoids at the peak."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Upright Rows", instructions: ExerciseInstructions(
            setup: "Stand holding a barbell or dumbbells in front of your thighs with an overhand grip slightly narrower than shoulder-width.",
            execution: "Pull the weight up along your body to chest height, leading with your elbows, then lower with control.",
            tips: "Keep the weight close to your body. Avoid going too high to prevent shoulder impingement."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Machine Shoulder Press", instructions: ExerciseInstructions(
            setup: "Sit in the machine with your back flat against the pad. Grip the handles at shoulder height.",
            execution: "Press the handles up until your arms are fully extended, then return to the starting position with control.",
            tips: "Adjust the seat height so the handles align with your shoulders. Keep your core engaged throughout."
        ), modelContext: modelContext)
        
        // ARMS EXERCISES
        updateExerciseInstructions(name: "Barbell Bicep Curl", instructions: ExerciseInstructions(
            setup: "Stand holding a barbell with an underhand grip at shoulder-width. Keep your elbows close to your body and core engaged.",
            execution: "Curl the bar up toward your shoulders, squeezing your biceps, then lower with control back to the starting position.",
            tips: "Keep your elbows stationary and avoid swinging. Focus on the bicep contraction at the top."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Dumbbell Bicep Curl", instructions: ExerciseInstructions(
            setup: "Stand holding dumbbells at your sides with an underhand grip. Keep your elbows close to your body and core engaged.",
            execution: "Curl the dumbbells up toward your shoulders, squeezing your biceps, then lower with control.",
            tips: "You can curl both arms together or alternate. Keep your elbows stationary and avoid swinging."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Hammer Curls", instructions: ExerciseInstructions(
            setup: "Stand holding dumbbells at your sides with a neutral grip (palms facing each other). Keep your elbows close to your body.",
            execution: "Curl the dumbbells up toward your shoulders, keeping your palms facing each other, then lower with control.",
            tips: "This grip targets the brachialis and forearms more than standard curls. Keep your elbows stationary."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Preacher Curls", instructions: ExerciseInstructions(
            setup: "Sit at a preacher bench with your arms resting on the pad. Hold an EZ bar or dumbbells with an underhand grip.",
            execution: "Curl the weight up, squeezing your biceps, then lower with control until your arms are fully extended.",
            tips: "The pad isolates the biceps by preventing swinging. Focus on a controlled negative (lowering) phase."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Cable Curls", instructions: ExerciseInstructions(
            setup: "Stand facing a cable machine with a handle attached at the bottom. Grip the handle with an underhand grip.",
            execution: "Curl the handle up toward your shoulders, squeezing your biceps, then lower with control.",
            tips: "Cables provide constant tension throughout the movement. Keep your elbows stationary and avoid swinging."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Tricep Pushdown", instructions: ExerciseInstructions(
            setup: "Stand facing a cable machine with a handle attached at the top. Grip the handle with an overhand grip, elbows at your sides.",
            execution: "Push the handle down until your arms are fully extended, squeezing your triceps, then return with control.",
            tips: "Keep your elbows close to your body and avoid swinging. Focus on the tricep contraction at the bottom."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Overhead Tricep Extension", instructions: ExerciseInstructions(
            setup: "Stand or sit holding a dumbbell or cable handle overhead with both hands, elbows pointing forward.",
            execution: "Lower the weight behind your head by bending your elbows, then extend back up to the starting position.",
            tips: "Keep your elbows pointing forward and avoid flaring them out. Focus on the tricep stretch and contraction."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Skull Crushers", instructions: ExerciseInstructions(
            setup: "Lie on a bench holding an EZ bar or barbell above your chest with your arms extended and elbows pointing forward.",
            execution: "Lower the weight toward your forehead by bending your elbows, then extend back up to the starting position.",
            tips: "Keep your elbows stationary and pointing forward. Don't let the weight touch your head - stop just above."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Tricep Dips", instructions: ExerciseInstructions(
            setup: "Grip parallel bars or a bench edge with your hands, supporting your body weight with your arms extended.",
            execution: "Lower your body by bending your elbows until you feel a stretch in your triceps, then push back up.",
            tips: "Keep your body upright to target triceps more. Avoid going too low to prevent shoulder strain."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Close-Grip Bench Press", instructions: ExerciseInstructions(
            setup: "Lie on a bench with your hands closer than shoulder-width apart on the barbell. Keep your elbows close to your body.",
            execution: "Lower the bar to your chest, then press it back up, focusing on using your triceps.",
            tips: "The close grip shifts emphasis to the triceps. Keep your elbows close to your body throughout."
        ), modelContext: modelContext)
        
        // LEGS EXERCISES
        updateExerciseInstructions(name: "Barbell Squat", instructions: ExerciseInstructions(
            setup: "Stand with the barbell across your upper back, feet shoulder-width apart. Keep your chest up and core engaged.",
            execution: "Lower your body by bending your knees and hips until your thighs are parallel to the floor, then drive back up through your heels.",
            tips: "Keep your knees tracking over your toes. Maintain a neutral spine and don't let your knees cave inward."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Front Squat", instructions: ExerciseInstructions(
            setup: "Stand with the barbell across your front shoulders, holding it with a clean grip or crossed arms. Keep your elbows up.",
            execution: "Lower your body by bending your knees and hips until your thighs are parallel to the floor, then drive back up.",
            tips: "Keep your torso upright and elbows high. This targets the quads more than back squats."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Goblet Squat", instructions: ExerciseInstructions(
            setup: "Hold a dumbbell or kettlebell at chest height with both hands. Stand with feet shoulder-width apart.",
            execution: "Lower your body by bending your knees and hips until your thighs are parallel to the floor, then drive back up.",
            tips: "Keep your torso upright and the weight close to your chest. Great for learning proper squat form."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Leg Press", instructions: ExerciseInstructions(
            setup: "Sit in the leg press machine with your feet shoulder-width apart on the platform. Keep your back flat against the pad.",
            execution: "Lower the platform by bending your knees until they form a 90-degree angle, then press back up to full extension.",
            tips: "Keep your knees tracking over your toes. Don't lock your knees at the top. Lower with control."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Romanian Deadlift", instructions: ExerciseInstructions(
            setup: "Stand holding a barbell or dumbbells in front of your thighs. Keep your back straight and core engaged.",
            execution: "Hinge at your hips, lowering the weight while keeping your legs relatively straight, then return to standing.",
            tips: "Keep your back straight and feel the stretch in your hamstrings. Don't round your back."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Leg Curl", instructions: ExerciseInstructions(
            setup: "Lie face down on the leg curl machine with your ankles under the pad. Keep your torso flat on the bench.",
            execution: "Curl your heels toward your glutes by bending your knees, squeezing your hamstrings, then lower with control.",
            tips: "Keep your hips down on the bench. Focus on the hamstring contraction at the peak of the movement."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Leg Extension", instructions: ExerciseInstructions(
            setup: "Sit in the leg extension machine with your shins against the pad. Keep your back flat against the seat.",
            execution: "Extend your legs until they're straight, squeezing your quads, then lower with control back to the starting position.",
            tips: "Keep your back against the seat and avoid swinging. Control the negative (lowering) phase."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Walking Lunges", instructions: ExerciseInstructions(
            setup: "Stand holding dumbbells at your sides or with just bodyweight. Take a step forward into a lunge position.",
            execution: "Lower your back knee toward the ground, then push through your front heel to step forward into the next lunge.",
            tips: "Keep your front knee over your ankle and your torso upright. Alternate legs as you walk forward."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Bulgarian Split Squat", instructions: ExerciseInstructions(
            setup: "Place your back foot on a bench behind you, holding a dumbbell in each hand. Keep your front foot flat on the ground.",
            execution: "Lower your body by bending your front knee until your thigh is parallel to the floor, then drive back up.",
            tips: "Keep your front knee tracking over your ankle. This is a single-leg exercise, so it's more challenging."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Calf Raises", instructions: ExerciseInstructions(
            setup: "Stand on a platform or flat ground with the balls of your feet on the edge. Hold weights or use bodyweight.",
            execution: "Raise up onto your toes as high as possible, squeezing your calves, then lower with control.",
            tips: "Keep your legs straight for gastrocnemius, or bend your knees slightly for soleus. Control the full range of motion."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Hip Thrust", instructions: ExerciseInstructions(
            setup: "Sit on the ground with your upper back against a bench, a barbell across your hips. Your feet should be flat on the floor.",
            execution: "Drive through your heels to lift your hips up, squeezing your glutes at the top, then lower with control.",
            tips: "Keep your chin tucked and core engaged. Focus on squeezing your glutes at the peak of the movement."
        ), modelContext: modelContext)
        
        // CORE EXERCISES
        updateExerciseInstructions(name: "Plank", instructions: ExerciseInstructions(
            setup: "Start in a push-up position with your forearms on the ground, elbows under your shoulders. Keep your body in a straight line.",
            execution: "Hold this position, keeping your core tight and body straight. Don't let your hips sag or rise.",
            tips: "Keep your head in line with your spine. Focus on breathing normally while maintaining the position."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Ab Rollout", instructions: ExerciseInstructions(
            setup: "Kneel on the ground holding an ab wheel or barbell with plates. Keep your core engaged and back straight.",
            execution: "Roll forward by extending your arms and hips, keeping your core tight, then roll back to the starting position.",
            tips: "Don't let your lower back arch excessively. Only go as far as you can maintain proper form."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Hanging Leg Raises", instructions: ExerciseInstructions(
            setup: "Hang from a pull-up bar with your arms fully extended. Keep your core engaged and legs straight or slightly bent.",
            execution: "Raise your legs up toward your chest, squeezing your abs, then lower with control back to the starting position.",
            tips: "Avoid swinging. Focus on using your abs to lift your legs, not momentum. You can bend your knees to make it easier."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Cable Crunches", instructions: ExerciseInstructions(
            setup: "Kneel facing a cable machine with a rope handle attached at the top. Hold the rope behind your head.",
            execution: "Curl your torso down, bringing your elbows toward your knees, squeezing your abs, then return to the starting position.",
            tips: "Keep your hips stationary and focus on crunching your abs, not pulling with your arms."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Russian Twists", instructions: ExerciseInstructions(
            setup: "Sit on the ground with your knees bent and feet elevated. Hold a weight or use bodyweight, lean back slightly.",
            execution: "Rotate your torso from side to side, bringing the weight or your hands to each side, keeping your core engaged.",
            tips: "Keep your back straight and avoid rounding. Focus on rotating with your core, not just your arms."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Dead Bug", instructions: ExerciseInstructions(
            setup: "Lie on your back with your arms extended toward the ceiling and knees bent at 90 degrees.",
            execution: "Lower your opposite arm and leg toward the ground while keeping your core engaged, then return and alternate sides.",
            tips: "Keep your lower back pressed to the ground. Move slowly and focus on core stability."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Bird Dog", instructions: ExerciseInstructions(
            setup: "Start on your hands and knees with your hands under your shoulders and knees under your hips.",
            execution: "Extend your opposite arm and leg straight out, keeping your core engaged and back straight, then return and alternate.",
            tips: "Keep your hips level and avoid rotating. Focus on stability and control throughout the movement."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Side Plank", instructions: ExerciseInstructions(
            setup: "Lie on your side with your forearm on the ground, elbow under your shoulder. Stack your feet and keep your body straight.",
            execution: "Lift your hips off the ground, forming a straight line from head to feet, and hold the position.",
            tips: "Keep your body in a straight line and avoid sagging. You can modify by bending your bottom knee."
        ), modelContext: modelContext)
        
        // CARDIO EXERCISES
        updateExerciseInstructions(name: "Outdoor Run", instructions: ExerciseInstructions(
            setup: "Wear appropriate running shoes and choose a safe route. Start with a light warm-up walk.",
            execution: "Run at a pace that allows you to maintain conversation. Focus on steady breathing and good running form.",
            tips: "Land on the middle of your foot, not your heel. Keep your posture upright and arms relaxed."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Treadmill Run", instructions: ExerciseInstructions(
            setup: "Set the treadmill to your desired speed and incline. Start with a warm-up walk.",
            execution: "Run at a steady pace, maintaining good form. Adjust speed and incline as needed.",
            tips: "Don't hold onto the handrails - let your arms swing naturally. Match the belt speed with your stride."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Interval Sprints", instructions: ExerciseInstructions(
            setup: "Warm up with light jogging. Choose a track, trail, or treadmill for your intervals.",
            execution: "Sprint at maximum effort for a set time or distance, then recover with walking or light jogging. Repeat.",
            tips: "Start with shorter intervals and longer recovery periods. Gradually increase intensity as you build fitness."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Outdoor Walk", instructions: ExerciseInstructions(
            setup: "Wear comfortable walking shoes. Choose a safe route with good footing.",
            execution: "Walk at a brisk pace that elevates your heart rate but allows you to maintain conversation.",
            tips: "Maintain good posture with your head up and shoulders back. Swing your arms naturally."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Treadmill Walk", instructions: ExerciseInstructions(
            setup: "Set the treadmill to a comfortable walking speed and incline. Start with a flat surface.",
            execution: "Walk at a steady pace, maintaining good posture. You can increase incline for more intensity.",
            tips: "Don't hold onto the handrails - let your arms swing naturally. Increase speed or incline gradually."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Incline Walk", instructions: ExerciseInstructions(
            setup: "Set the treadmill to a comfortable walking speed with an elevated incline (5-15%).",
            execution: "Walk at a steady pace up the incline, maintaining good posture and engaging your glutes and calves.",
            tips: "Start with a lower incline and gradually increase. This is great for building lower body strength."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Outdoor Cycling", instructions: ExerciseInstructions(
            setup: "Ensure your bike is properly adjusted and you're wearing a helmet. Choose a safe route.",
            execution: "Pedal at a steady cadence, maintaining good form. Adjust your pace based on terrain and fitness level.",
            tips: "Keep your core engaged and maintain a smooth pedaling motion. Shift gears appropriately for hills."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Stationary Bike", instructions: ExerciseInstructions(
            setup: "Adjust the seat height so your leg is almost fully extended at the bottom of the pedal stroke.",
            execution: "Pedal at a steady cadence, adjusting resistance as needed. Maintain good posture throughout.",
            tips: "Keep your core engaged and avoid slouching. You can do intervals by varying resistance and speed."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Spin Class", instructions: ExerciseInstructions(
            setup: "Adjust your bike seat and handlebars to proper height. Follow the instructor's guidance for setup.",
            execution: "Follow the class format, which typically includes warm-up, intervals, and cool-down phases.",
            tips: "Listen to your body and adjust resistance as needed. Stay hydrated and maintain good form throughout."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Rowing Machine", instructions: ExerciseInstructions(
            setup: "Sit on the rower with your feet secured in the straps. Grip the handle with an overhand grip.",
            execution: "Drive with your legs, then lean back slightly and pull the handle to your chest, then reverse the motion.",
            tips: "The sequence is legs, then core, then arms. Return in reverse order. Keep your back straight."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Stair Climber", instructions: ExerciseInstructions(
            setup: "Step onto the machine and select your desired speed and resistance level.",
            execution: "Climb at a steady pace, maintaining good posture. Keep your core engaged and avoid leaning on the handrails.",
            tips: "Use the handrails for balance only, not to support your weight. Focus on pushing through your heels."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Stadium Stairs", instructions: ExerciseInstructions(
            setup: "Find a set of stadium stairs or a tall staircase. Warm up with light walking.",
            execution: "Climb the stairs at a brisk pace, using every step or every other step. Walk down for recovery.",
            tips: "Maintain good posture and use the handrail if needed for safety. Start with shorter sessions and build up."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Jump Rope", instructions: ExerciseInstructions(
            setup: "Hold the rope handles at your sides with the rope behind you. Stand with feet together and knees slightly bent.",
            execution: "Jump over the rope as it passes under your feet, landing on the balls of your feet. Maintain a steady rhythm.",
            tips: "Keep your elbows close to your body and rotate with your wrists, not your arms. Start slow and build speed."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Elliptical", instructions: ExerciseInstructions(
            setup: "Step onto the elliptical and select your desired resistance and incline level.",
            execution: "Move your legs in a smooth elliptical motion, maintaining good posture. Use the moving handles for upper body engagement.",
            tips: "Keep your core engaged and avoid slouching. You can go forward or backward to target different muscles."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "Swimming", instructions: ExerciseInstructions(
            setup: "Enter the pool and choose your stroke (freestyle, breaststroke, etc.). Warm up with easy laps.",
            execution: "Swim at a steady pace, focusing on good form and breathing rhythm. Rest between laps as needed.",
            tips: "Focus on smooth, efficient strokes. Breathe regularly and maintain a consistent pace."
        ), modelContext: modelContext)
        
        updateExerciseInstructions(name: "HIIT Session", instructions: ExerciseInstructions(
            setup: "Choose a combination of exercises (burpees, jumping jacks, mountain climbers, etc.). Warm up with light movement.",
            execution: "Perform each exercise at maximum effort for a set time (20-60 seconds), then rest for equal or shorter time. Repeat.",
            tips: "Maintain good form even when fatigued. Start with shorter work intervals and longer rest periods."
        ), modelContext: modelContext)
        
        // Save after all updates
        do {
            try modelContext.save()
        } catch {
            print("Error updating exercise instructions: \(error)")
        }
    }
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var exercisesByCategory: [String: [Exercise]] {
        Dictionary(grouping: filteredExercises) { $0.category }
    }
    
    var sortedCategories: [String] {
        exercisesByCategory.keys.sorted { $0 < $1 }
    }
}
