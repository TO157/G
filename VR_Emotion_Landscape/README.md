# VR Emotion-Driven Dynamic Landscape System

## Overview

This project is a Luau-based system designed for VR applications that dynamically generates and modifies interactive landscapes based on simulated user emotions. It showcases a modular approach to building complex systems with clear separation of concerns, from emotion detection to landscape rendering and user interaction.

## Features

*   **Emotion Detection:** Classifies user emotions (calm, excited, stressed, neutral) from simulated biometric data (heart rate, skin conductance).
*   **Dynamic Landscape Generation:** Creates unique landscape themes, objects, and weather patterns tailored to the detected emotion.
*   **User Interaction:** Allows users to interact with the landscape, such as planting new objects or changing the current weather.
*   **Data Persistence:** Simulates saving and loading of user-specific landscape states, allowing for session continuity.
*   **Modular Design:** Core functionalities are encapsulated in separate modules (e.g., EmotionDetection, LandscapeGenerator, Persistence).
*   **Service Layer:** A service layer (`LandscapeService`) orchestrates the modules to provide cohesive system behavior.
*   **Logging:** Includes a simple logging utility for monitoring system events and aiding in debugging.
*   **Typed Luau:** Utilizes Luau type annotations for improved code clarity and robustness.

## Project Structure

The project is organized into the following main directories:

```
VR_Emotion_Landscape/
├── src/                      # Source code
│   ├── Modules/              # Core logic modules
│   │   ├── EmotionDetection.luau
│   │   ├── LandscapeGenerator.luau
│   │   ├── UserInteraction.luau
│   │   ├── Persistence.luau
│   │   └── Logger.luau
│   ├── Services/             # Service layer orchestrating modules
│   │   └── LandscapeService.luau
│   ├── Types/                # Luau type definitions
│   │   └── init.luau
│   └── main.luau             # Main simulation script
├── tests/                    # Unit test scripts (mirroring src structure)
│   ├── Modules/
│   │   ├── EmotionDetection.spec.luau
│   │   ├── LandscapeGenerator.spec.luau
│   │   ├── UserInteraction.spec.luau
│   │   ├── Persistence.spec.luau
│   │   └── Logger.spec.luau
│   └── Services/
│       └── LandscapeService.spec.luau
└── README.md                 # This file
```

*   `src/`: Contains all the source code for the system.
*   `src/Modules/`: Houses individual modules responsible for specific functionalities.
*   `src/Services/`: Contains the service layer that coordinates the modules.
*   `src/Types/`: Defines shared Luau data types and structures used throughout the project.
*   `src/main.luau`: An example script that runs a simulation of the system.
*   `tests/`: Includes unit tests for each module and service to ensure functionality and enable test-driven development. (The `...` in the example structure indicates that other spec files like `LandscapeGenerator.spec.luau` are present).

## Modules Overview

*   **`Types/init.luau`**: Defines all shared data structures and custom types (e.g., `BiometricData`, `Emotion`, `LandscapeState`) used across the system, ensuring consistency.
*   **`Modules/Logger.luau`**: Provides basic logging functionalities (`info`, `warn`, `error`) to output messages to the console, aiding in debugging and tracing system behavior.
*   **`Modules/EmotionDetection.luau`**: Responsible for processing simulated biometric data to classify the user's current emotional state (e.g., "calm", "excited"). Includes functions to get simulated data based on a mood string.
*   **`Modules/LandscapeGenerator.luau`**: Dynamically generates the virtual landscape based on the classified emotion. This includes selecting themes, populating objects, and setting initial weather conditions.
*   **`Modules/UserInteraction.luau`**: Manages user interactions within the landscape, such as planting new objects or modifying environmental parameters like weather.
*   **`Modules/Persistence.luau`**: Simulates the saving and loading of landscape states. In this project, it uses an in-memory mock database. Conceptual notes are included for integration with persistent storage like Lute.
*   **`Services/LandscapeService.luau`**: Acts as an orchestrator, coordinating the various modules to provide higher-level functionalities like initializing a user session, updating the landscape based on new emotions, handling user interactions, and managing data persistence.
*   **`main.luau`**: A demonstration script that simulates a user's journey through the system, showcasing initialization, emotion changes, interactions, and persistence.

## How to Run

### Simulation

To run the main simulation script:
1.  Ensure you have a Luau runtime environment (e.g., `luau` CLI, or within a supporting engine like Roblox).
2.  Navigate to the `src` directory in your terminal.
3.  Execute the `main.luau` script:
    ```bash
    luau main.luau
    ```
    This will print log messages to the console, showing the simulation steps and state changes.

### Tests

To run the unit tests:
1.  Navigate to the directory containing the test script you want to run (e.g., `tests/Modules/` or `tests/Services/`).
2.  Execute the desired `.spec.luau` file using the Luau runtime:
    ```bash
    # Example for EmotionDetection tests
    # From the project root:
    luau tests/Modules/EmotionDetection.spec.luau

    # Example for LandscapeService tests
    # From the project root:
    luau tests/Services/LandscapeService.spec.luau
    ```
    Each test script will print output indicating test success or failure, often including specific log messages from the `Logger` module.

## Assumptions & Limitations

*   **Simulated Data:** Biometric data for emotion detection is simulated; no actual hardware sensor integration is implemented.
*   **Mocked Persistence:** Landscape state persistence is mocked using an in-memory table. Data is not saved to disk between separate executions of the `main.luau` script or test runs.
*   **VR Abstraction:** Specifics of the VR environment, such as rendering, 3D asset loading, detailed input event systems, and display management, are abstracted. The focus is on the logic of the emotion-driven system.
*   **Lute Runtime:** The use of the Lute runtime for more advanced persistence and performance is discussed conceptually in comments within the `Persistence.luau` module but is not a direct dependency or implementation in this project.
*   **`Color3` and `Vector3`:** These types are assumed to be provided by the VR environment or a graphics library as global constructors (e.g., `Color3.new()`, `Vector3.new()`). For the simulation, they are treated as simple Luau tables where appropriate (e.g., `{x, y, z}`).

---
This README provides a comprehensive guide to the VR Emotion-Driven Dynamic Landscape System.
