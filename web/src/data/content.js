import {
  QrCode, Volume2, Wallet, Smartphone, BarChart3, Users, ShieldCheck, Coins,
  Bell, Route, Clock, FileText, Banknote, Gauge, Truck, UserCheck, LayoutDashboard,
} from "lucide-react";

export const TABS = {
  Pasajero: [
    [QrCode, "QR fijo en la unidad", "Escanea el código del asiento o la puerta y paga desde la app de tu banco."],
    [Banknote, "Sin cambio", "Paga $10 o $12 exactos. Ya no necesitas monedas."],
    [Clock, "Subes más rápido", "El pago toma segundos y la fila avanza sin discusiones."],
    [ShieldCheck, "Pago seguro", "El cobro pasa por CoDi y tu banco lo confirma al instante."],
    [Coins, "Sin comisión", "Un pasaje de $10 no se cobra con tarjeta. Con CoDi sí."],
    [FileText, "Comprobante", "Tu banco guarda cada viaje como respaldo."],
  ],
  Chofer: [
    [Volume2, "Aviso de voz", "Una bocina dice “pagó” cada vez que entra un cobro."],
    [Bell, "Sin ver pantallas", "Manejas con la vista en el camino."],
    [Smartphone, "Celular o bocina", "Funciona en tu teléfono o con una bocina ESP32."],
    [Route, "Tu ruta, tu turno", "Cada cobro queda ligado a tu turno y a tu unidad."],
    [UserCheck, "Cuentas claras", "Tu cuadre es el mismo que ve el dueño."],
    [Gauge, "Menos efectivo", "Terminas el día con menos dinero encima."],
  ],
  Dueño: [
    [Wallet, "Dinero directo", "Los cobros caen en tu Cuenta Destino como titular."],
    [BarChart3, "Cuadre del día", "Ve cuánto entró por unidad y por chofer."],
    [Truck, "Todas tus unidades", "Da de alta cada combi con su propio QR."],
    [Users, "Turnos comparables", "Detecta diferencias entre viajes y dinero cobrado."],
    [LayoutDashboard, "Panel en vivo", "Mira los cobros llegar desde cualquier navegador."],
    [FileText, "Historial", "Consulta cada cobro por fecha, unidad y horario."],
  ],
};

export const OPINIONES = [
  ["Ya no cuento monedas. Cierro el turno y el cuadre ya está hecho.", "Marcos Peña", "Chofer, Ruta 52"],
  ["Por primera vez sé cuánto entra por unidad sin preguntarle a nadie.", "Lucía Romero", "Dueña de 4 combis"],
  ["Escaneo, pago y subo. No tengo que pedir cambio.", "Daniel Soto", "Pasajero"],
  ["La bocina dice “pagó” y yo sigo viendo la calle.", "Ana Beltrán", "Choferesa, Ruta 7"],
];

export const PASOS = [
  ["Da de alta tu unidad y tu CLABE", "El dueño registra sus combis. Los pagos llegan a su Cuenta Destino con CoDi."],
  ["Pega el QR fijo en la unidad", "Cada combi tiene su código. El pasajero lo escanea y paga $10 o $12."],
  ["Escucha “pagó” y revisa el cuadre", "El aviso confirma cada cobro y el panel suma el total por chofer."],
];
