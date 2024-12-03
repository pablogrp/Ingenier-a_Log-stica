# Importar los paquetes necesarios
using Pkg
Pkg.add("JuMP")  # Paquete para modelar problemas de optimización
Pkg.add("GLPK")  # Paquete para utilizar el solver GLPK

using JuMP, GLPK, Random

# Definir parámetros iniciales
num_clientes = 4            # Cantidad de clientes
num_empleados = num_clientes # Cantidad de empleados (igual al número de clientes)
num_vehiculos = num_empleados # Cantidad de vehículos (igual al número de empleados)

# Semilla para reproducibilidad
Random.seed!(2160)

# Matriz de costos: coste de asignar un empleado y un vehiculo a cada cliente
costos = rand(20:60, num_clientes, num_empleados, num_vehiculos)

# Crear el modelo de optimización
modelo = Model(GLPK.Optimizer)
set_silent(modelo)  # Suprimir la salida del solver

# Definir variables binarias (1 si el empleado usa el vehículo para el cliente, 0 si no)
@variable(modelo, asignacion[1:num_clientes, 1:num_empleados, 1:num_vehiculos], Bin)

# Función objetivo: minimizar el coste total
@objective(modelo, Min, sum(costos[c, e, m] * asignacion[c, e, m] 
                            for c in 1:num_clientes, e in 1:num_empleados, m in 1:num_vehiculos))
# Restricciones:
# Cada vehñiculo puede asignarse solo a un cliente y un empleado
@constraint(modelo, [m=1:num_vehiculos], sum(asignacion[:, :, m]) == 1)
# Cada cliente debe ser atendido por exactamente un empleado y un vehículo
@constraint(modelo, [c=1:num_clientes], sum(asignacion[c, :, :]) == 1)
# Cada empleado puede manejar una máquina para un cliente
@constraint(modelo, [e=1:num_empleados], sum(asignacion[:, e, :]) == 1)

# Resolver el modelo
optimize!(modelo)

# Mostrar los resultados
if termination_status(modelo) == MOI.OPTIMAL
    println("Costo total: ", objective_value(modelo), " €.")
    println()
    for c in 1:num_clientes
        for e in 1:num_empleados
            for m in 1:num_vehiculos
                # Comprobar si la asignación es válida
                if value(asignacion[c, e, m]) > 0.5
                    println("El empleado $e utiliza el vehiculo $m para atender al cliente $c. Coste: ", 
                            costos[c, e, m], " €.")
                end
            end
        end
    end
else
    println("No se encontró una solución óptima para el problema.")
end
