
# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     AzarApp.Repo.insert!(%AzarApp.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias AzarApp.Repo
alias AzarApp.Cuentas

# Crear usuario admin
Cuentas.crear_usuario(%{
  email: "admin@azar.com",
  password: "admin123456",
  nombre: "Administrador Azar",
  rol: "admin",
  edad: 35,
  cedula: "1234567890"
})

# Crear usuario cliente de prueba
Cuentas.crear_usuario(%{
  email: "cliente@azar.com",
  password: "cliente123456",
  nombre: "Juan Pérez",
  rol: "cliente",
  edad: 28,
  cedula: "9876543210"
})

IO.puts("✓ Usuarios creados: admin@azar.com y cliente@azar.com")
