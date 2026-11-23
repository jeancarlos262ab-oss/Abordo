// Ilustración decorativa: marco con bocina y botón de inicio, descrita como una sola imagen.
export default function Phone({ variant = "light", className = "", label, children }) {
  return (
    <div className={`phone ${variant} ${className}`} role="img" aria-label={label}>
      <span className="spk" />
      <div className="screen">{children}</div>
      <span className="home" />
    </div>
  );
}
