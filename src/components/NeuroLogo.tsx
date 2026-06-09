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
      {/*
        Brain silhouette — filled, two-lobe top with 18-unit center dip so both
        hemispheres read clearly even at 14px. No internal lines needed.
      */}
      <path
        d="M 50 26
           C 46 12, 26 8, 17 22
           C 8 34, 10 46, 9 57
           C 8 68, 17 80, 31 82
           C 39 83, 47 79, 50 75
           C 53 79, 61 83, 69 82
           C 83 80, 92 68, 91 57
           C 90 46, 92 34, 83 22
           C 74 8, 54 12, 50 26 Z"
        fill="currentColor"
      />
    </svg>
  );
}
