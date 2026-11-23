import { useState } from "react";
import { Menu } from "lucide-react";

const LINKS = [["Opiniones", "#opiniones"], ["Funciones", "#funciones"], ["Cómo funciona", "#como-funciona"]];

export default function Header() {
  const [open, setOpen] = useState(false);
  return (
    <header className="top">
      <a className="logo" href="#contenido">ABORDO</a>
      <nav id="menu" aria-label="Principal" className={open ? "open" : ""}>
        <ul role="list">
          {LINKS.map(([t, h]) => <li key={h}><a href={h} onClick={() => setOpen(false)}>{t}</a></li>)}
        </ul>
      </nav>
      <button className="burger" aria-expanded={open} aria-controls="menu" onClick={() => setOpen((o) => !o)}>
        <Menu size={22} aria-hidden="true" focusable="false" /><span className="sr">Menú</span>
      </button>
    </header>
  );
}
