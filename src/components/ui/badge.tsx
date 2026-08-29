import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const badgeVariants = cva(
  "inline-flex items-center justify-center font-extrabold transition-all select-none",
  {
    variants: {
      color: {
        default: "bg-zinc-800 text-zinc-200 border-zinc-700",
        primary: "bg-primary text-primary-foreground shadow-sm shadow-primary/40",
        secondary: "bg-purple-600 text-white shadow-sm shadow-purple-600/40",
        success: "bg-emerald-500 text-black shadow-sm shadow-emerald-500/40",
        warning: "bg-amber-500 text-black shadow-sm shadow-amber-500/40",
        danger: "bg-rose-500 text-white shadow-sm shadow-rose-500/40",
      },
      variant: {
        solid: "border-transparent",
        flat: "bg-opacity-20 border-transparent",
        bordered: "bg-transparent border-2",
        dot: "size-2.5 p-0 rounded-full animate-pulse",
      },
      size: {
        sm: "px-2 py-0.5 text-[10px] rounded-lg",
        md: "px-2.5 py-0.5 text-xs rounded-xl",
        lg: "px-3 py-1 text-sm rounded-xl",
      },
      shape: {
        rectangle: "rounded-xl",
        circle: "rounded-full min-w-5 h-5 px-1.5",
      },
    },
    defaultVariants: {
      color: "primary",
      variant: "solid",
      size: "md",
      shape: "rectangle",
    },
  }
);

export interface BadgeProps
  extends Omit<React.HTMLAttributes<HTMLDivElement>, "color" | "content">,
    VariantProps<typeof badgeVariants> {
  content?: React.ReactNode;
  isInvisible?: boolean;
  placement?: "top-right" | "bottom-right" | "top-left" | "bottom-left";
}

function Badge({
  className,
  color,
  variant,
  size,
  shape,
  content,
  isInvisible = false,
  placement = "top-right",
  children,
  ...props
}: BadgeProps) {
  if (children) {
    return (
      <div className="relative inline-flex shrink-0">
        {children}
        {!isInvisible && (
          <span
            className={cn(
              "absolute z-10 flex items-center justify-center font-black font-mono shadow-md",
              badgeVariants({ color, variant, size, shape }),
              placement === "top-right" && "top-0 right-0 -translate-y-1/3 translate-x-1/3",
              placement === "bottom-right" && "bottom-0 right-0 translate-y-1/3 translate-x-1/3",
              placement === "top-left" && "top-0 left-0 -translate-y-1/3 -translate-x-1/3",
              placement === "bottom-left" && "bottom-0 left-0 translate-y-1/3 -translate-x-1/3",
              className
            )}
            {...props}
          >
            {variant === "dot" ? null : content}
          </span>
        )}
      </div>
    );
  }

  return (
    <div
      className={cn(badgeVariants({ color, variant, size, shape }), className)}
      {...props}
    >
      {variant === "dot" ? null : content}
    </div>
  );
}

export { Badge, badgeVariants };
