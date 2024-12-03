# Importar los paquetes necesarios
using Pkg
Pkg.add("JuMP")  # Paquete para modelar problemas de optimización matemática en Julia.
Pkg.add("GLPK")  # GLPK es un solver para problemas de optimización lineal y entera.

using JuMP, GLPK, Random

# Definir parámetros del problema
num_workers = 2      # Número de trabajadores.
num_shifts = 4      # Número de turnos disponibles por trabajador.
num_tasks = 24       # Número total de tareas.
Random.seed!(1234)    # Establecer la semilla para la aleatoriedad, de modo que los resultados sean reproducibles.

# Generar valores aleatorios para la prioridad (P) y la capacidad (C)
priority = rand(1:10, num_workers, num_shifts, num_tasks)  # Prioridad asociada a cada tarea para cada trabajador en cada turno.
capacity = rand(1:2, num_workers, num_shifts)              # Capacidad de cada turno para cada trabajador.

# Crear un modelo de optimización con el solver GLPK
optimization_model = Model(GLPK.Optimizer)
set_silent(optimization_model)  # Configurar el modelo para que no muestre mensajes durante la optimización.

# Definir variables de decisión
# `assign[w, s, t]` es una variable binaria que indica si la tarea `t` está asignada al turno `s` del trabajador `w`.
@variable(optimization_model, assign[1:num_workers, 1:num_shifts, 1:num_tasks] >= 0, binary=true)

# Definir la función objetivo
# Maximizar la prioridad total por la asignación de tareas.
@objective(optimization_model, Max, sum(priority[w, s, t] * assign[w, s, t] for w in 1:num_workers, s in 1:num_shifts, t in 1:num_tasks))

# Definir restricciones
# Restricción 1: Cada tarea debe ser asignada a un único turno y trabajador.
@constraint(optimization_model, task_assignment[t=1:num_tasks], sum(assign[:, :, t]) == 1)

# Restricción 2: Cada turno de cada trabajador debe tener al menos una tarea asignada.
@constraint(optimization_model, worker_shift[w=1:num_workers, s=1:num_shifts], sum(assign[w, s, :]) >= 1)

# Restricción 3: La cantidad de tareas en un turno no debe exceder la capacidad de ese turno.
@constraint(optimization_model, shift_capacity[w=1:num_workers, s=1:num_shifts], sum(assign[w, s, :]) <= capacity[w, s])

# Optimizar el modelo
optimize!(optimization_model)

# Obtener y mostrar los resultados
max_priority = objective_value(optimization_model)
println("Prioridad máxima alcanzada: ", max_priority)
println()
println("Trabajadores y turnos:")

# Mostrar la asignación de tareas a los turnos y trabajadores
for w in 1:num_workers
    println("  Trabajador $w")
    for s in 1:num_shifts
        shift_capacity_value = capacity[w, s]  # Capacidad del turno `s` del trabajador `w`.
        println("    Turno $s con capacidad para $shift_capacity_value tareas. Contiene las tareas:")
        task_found = false  # Bandera para verificar si hay tareas en este turno.
        for t in 1:num_tasks
            if value(assign[w, s, t]) > 0  # Si la tarea `t` está asignada a este turno.
                task_found = true
                println("      * Tarea $t")
            end
        end
    end
    println()
end
