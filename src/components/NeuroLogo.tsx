interface Props {
  size?: number;
  className?: string;
}

export default function NeuroLogo({ size = 20, className = '' }: Props) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 100 100"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
      aria-label="NeuroSync"
    >
      <line x1="27" y1="25" x2="27" y2="75" stroke="currentColor" strokeWidth="7" strokeLinecap="round" strokeOpacity="0.95"/>
      <line x1="27" y1="25" x2="73" y2="75" stroke="currentColor" strokeWidth="7" strokeLinecap="round" strokeOpacity="0.75"/>
      <line x1="73" y1="25" x2="73" y2="75" stroke="currentColor" strokeWidth="7" strokeLinecap="round" strokeOpacity="0.95"/>
      <circle cx="27" cy="25" r="7" fill="currentColor"/>
      <circle cx="27" cy="75" r="7" fill="currentColor"/>
      <circle cx="73" cy="25" r="7" fill="currentColor"/>
      <circle cx="73" cy="75" r="7" fill="currentColor"/>
    </svg>
  );
}
