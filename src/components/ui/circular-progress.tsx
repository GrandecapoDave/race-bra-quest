import React from "react";

interface CircularProgressProps {
  value: number; // 0 to 100
  size?: number; // diameter in pixels (default 64)
  strokeWidth?: number; // stroke width (default 6)
  color?: string; // stroke color class (default text-primary)
  trackColor?: string; // track background stroke (default text-muted/30)
  className?: string;
  children?: React.ReactNode;
}

export function CircularProgress({
  value,
  size = 64,
  strokeWidth = 6,
  color = "text-primary",
  trackColor = "text-border/40",
  className = "",
  children,
}: CircularProgressProps) {
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const clampedValue = Math.min(100, Math.max(0, value));
  const strokeDashoffset = circumference - (clampedValue / 100) * circumference;

  return (
    <div
      className={`relative inline-flex items-center justify-center ${className}`}
      style={{ width: size, height: size }}
    >
      <svg
        width={size}
        height={size}
        viewBox={`0 0 ${size} ${size}`}
        className="-rotate-90 transform"
      >
        {/* Track */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          strokeWidth={strokeWidth}
          stroke="currentColor"
          fill="transparent"
          className={trackColor}
        />
        {/* Progress Ring */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          strokeWidth={strokeWidth}
          stroke="currentColor"
          fill="transparent"
          strokeDasharray={circumference}
          strokeDashoffset={strokeDashoffset}
          strokeLinecap="round"
          className={`${color} transition-all duration-700 ease-out`}
        />
      </svg>
      {/* Centered Content */}
      <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
        {children}
      </div>
    </div>
  );
}
