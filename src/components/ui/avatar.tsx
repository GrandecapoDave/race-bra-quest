"use client";

import * as React from "react";
import { cn } from "@/lib/utils";

export interface HeroAvatarProps extends React.HTMLAttributes<HTMLDivElement> {
  src?: string | null;
  name?: string | null;
  emoji?: string | null;
  icon?: React.ReactNode;
  fallback?: React.ReactNode;
  size?: "xs" | "sm" | "md" | "lg" | "xl" | "2xl";
  radius?: "none" | "sm" | "md" | "lg" | "full";
  color?: "default" | "primary" | "secondary" | "success" | "warning" | "danger" | string;
  isBordered?: boolean;
  isDisabled?: boolean;
  isHoverable?: boolean;
  isPressable?: boolean;
  badge?: React.ReactNode;
  badgePlacement?: "top-right" | "bottom-right" | "bottom-left" | "top-left";
}

const sizeClasses: Record<NonNullable<HeroAvatarProps["size"]>, string> = {
  xs: "w-6 h-6 text-xs",
  sm: "w-8 h-8 text-sm",
  md: "w-10 h-10 text-base",
  lg: "w-14 h-14 text-2xl",
  xl: "w-20 h-20 text-3xl",
  "2xl": "w-24 h-24 text-4xl",
};

const radiusClasses: Record<NonNullable<HeroAvatarProps["radius"]>, string> = {
  none: "rounded-none",
  sm: "rounded-lg",
  md: "rounded-xl",
  lg: "rounded-2xl",
  full: "rounded-full",
};

const colorRingClasses: Record<string, string> = {
  default: "ring-zinc-600 shadow-zinc-900/50",
  primary: "ring-primary shadow-primary/30",
  secondary: "ring-purple-500 shadow-purple-500/30",
  success: "ring-emerald-500 shadow-emerald-500/30",
  warning: "ring-amber-500 shadow-amber-500/30",
  danger: "ring-rose-500 shadow-rose-500/30",
};

export const HeroAvatar = React.forwardRef<HTMLDivElement, HeroAvatarProps>(
  (
    {
      className,
      src,
      name,
      emoji,
      icon,
      fallback,
      size = "md",
      radius = "full",
      color = "default",
      isBordered = false,
      isDisabled = false,
      isHoverable = false,
      isPressable = false,
      badge,
      badgePlacement = "bottom-right",
      style,
      ...props
    },
    ref
  ) => {
    const isCustomHex = color && color.startsWith("#");
    const ringClass = isBordered
      ? isCustomHex
        ? "ring-2 ring-offset-2 ring-offset-zinc-950"
        : `ring-2 ring-offset-2 ring-offset-zinc-950 ${colorRingClasses[color] || "ring-primary shadow-primary/25"}`
      : "";

    const customStyle: React.CSSProperties = {
      ...(isCustomHex && isBordered ? ({ "--tw-ring-color": color } as any) : {}),
      ...style,
    };

    return (
      <div
        ref={ref}
        style={customStyle}
        className={cn(
          "relative inline-flex items-center justify-center shrink-0 select-none bg-zinc-900/90 text-foreground font-display font-extrabold shadow-md",
          sizeClasses[size],
          radiusClasses[radius],
          ringClass,
          isDisabled && "opacity-40 grayscale cursor-not-allowed pointer-events-none",
          isHoverable && "transition-transform duration-200 hover:scale-105",
          isPressable && "cursor-pointer active:scale-95 transition-transform duration-150",
          className
        )}
        {...props}
      >
        {src ? (
          <img
            src={src}
            alt={name || "Avatar"}
            className={cn("w-full h-full object-cover", radiusClasses[radius])}
          />
        ) : emoji ? (
          <span className="flex items-center justify-center pointer-events-none drop-shadow-sm">
            {emoji}
          </span>
        ) : icon ? (
          <span className="flex items-center justify-center pointer-events-none">{icon}</span>
        ) : name ? (
          <span className="uppercase tracking-wider">
            {name
              .split(" ")
              .map((n) => n[0])
              .join("")
              .slice(0, 2)}
          </span>
        ) : (
          fallback || "👤"
        )}

        {/* Status Badge */}
        {badge && (
          <span
            className={cn(
              "absolute z-10 flex items-center justify-center",
              badgePlacement === "bottom-right" && "-bottom-1 -right-1",
              badgePlacement === "top-right" && "-top-1 -right-1",
              badgePlacement === "bottom-left" && "-bottom-1 -left-1",
              badgePlacement === "top-left" && "-top-1 -left-1"
            )}
          >
            {badge}
          </span>
        )}
      </div>
    );
  }
);
HeroAvatar.displayName = "HeroAvatar";

export interface AvatarGroupProps extends React.HTMLAttributes<HTMLDivElement> {
  max?: number;
  total?: number;
  size?: HeroAvatarProps["size"];
  radius?: HeroAvatarProps["radius"];
  isBordered?: boolean;
  children: React.ReactNode;
}

export function AvatarGroup({
  className,
  max = 4,
  total,
  size = "md",
  radius = "full",
  isBordered = true,
  children,
  ...props
}: AvatarGroupProps) {
  const childrenArray = React.Children.toArray(children);
  const visibleAvatars = childrenArray.slice(0, max);
  const remainingCount = (total ?? childrenArray.length) - visibleAvatars.length;

  return (
    <div
      className={cn("flex items-center -space-x-2.5 rtl:space-x-reverse overflow-visible", className)}
      {...props}
    >
      {visibleAvatars.map((child, index) => {
        if (React.isValidElement<HeroAvatarProps>(child)) {
          return React.cloneElement(child, {
            key: index,
            size: child.props.size || size,
            radius: child.props.radius || radius,
            isBordered: child.props.isBordered !== undefined ? child.props.isBordered : isBordered,
            className: cn("ring-2 ring-zinc-950 transition-transform hover:z-20 hover:scale-110", child.props.className),
          });
        }
        return child;
      })}

      {remainingCount > 0 && (
        <HeroAvatar
          size={size}
          radius={radius}
          isBordered={isBordered}
          className="bg-zinc-800 text-zinc-300 ring-2 ring-zinc-950 text-xs font-bold font-mono z-10"
          fallback={`+${remainingCount}`}
        />
      )}
    </div>
  );
}

// Backward compatibility with standard Radix exports
export { HeroAvatar as Avatar };
const AvatarImage = (props: any) => <img {...props} />;
const AvatarFallback = ({ children, className }: any) => <span className={className}>{children}</span>;
export { AvatarImage, AvatarFallback };
