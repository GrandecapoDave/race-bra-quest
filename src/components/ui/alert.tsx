import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const alertVariants = cva(
  "relative w-full rounded-2xl p-4 text-sm flex items-start gap-3.5 transition-all shadow-md",
  {
    variants: {
      color: {
        default: "bg-zinc-900/90 border border-zinc-800 text-zinc-200",
        primary: "bg-primary/10 border border-primary/30 text-primary-foreground shadow-primary/10",
        secondary: "bg-purple-500/10 border border-purple-500/30 text-purple-200 shadow-purple-500/10",
        success: "bg-emerald-500/10 border border-emerald-500/30 text-emerald-200 shadow-emerald-500/10",
        warning: "bg-amber-500/10 border border-amber-500/30 text-amber-200 shadow-amber-500/10",
        danger: "bg-rose-500/10 border border-rose-500/30 text-rose-200 shadow-rose-500/10",
      },
      variant: {
        flat: "",
        bordered: "bg-transparent border-2",
        solid: "text-white font-bold",
        faded: "bg-zinc-950/60 backdrop-blur-md border",
      },
    },
    defaultVariants: {
      color: "default",
      variant: "faded",
    },
  }
);

export interface AlertProps
  extends Omit<React.HTMLAttributes<HTMLDivElement>, "color" | "title">,
    VariantProps<typeof alertVariants> {
  icon?: React.ReactNode;
  title?: React.ReactNode;
  description?: React.ReactNode;
  action?: React.ReactNode;
  onClose?: () => void;
}

const Alert = React.forwardRef<HTMLDivElement, AlertProps>(
  ({ className, color = "default", variant = "faded", icon, title, description, action, onClose, children, ...props }, ref) => (
    <div
      ref={ref}
      role="alert"
      className={cn(alertVariants({ color, variant }), className)}
      {...props}
    >
      {icon && <div className="shrink-0 mt-0.5">{icon}</div>}
      <div className="flex-1 space-y-1 min-w-0">
        {title && <h5 className="font-extrabold text-sm leading-tight tracking-wide">{title}</h5>}
        {description && <div className="text-xs text-muted-foreground leading-relaxed">{description}</div>}
        {children}
      </div>
      {action && <div className="shrink-0 self-center">{action}</div>}
      {onClose && (
        <button
          type="button"
          onClick={onClose}
          className="shrink-0 p-1 text-muted-foreground hover:text-white rounded-lg hover:bg-white/10 transition-colors"
        >
          ✕
        </button>
      )}
    </div>
  )
);
Alert.displayName = "Alert";

const AlertTitle = React.forwardRef<HTMLParagraphElement, React.HTMLAttributes<HTMLHeadingElement>>(
  ({ className, ...props }, ref) => (
    <h5
      ref={ref}
      className={cn("font-extrabold text-sm leading-none tracking-tight", className)}
      {...props}
    />
  )
);
AlertTitle.displayName = "AlertTitle";

const AlertDescription = React.forwardRef<HTMLParagraphElement, React.HTMLAttributes<HTMLParagraphElement>>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn("text-xs text-muted-foreground leading-relaxed", className)} {...props} />
  )
);
AlertDescription.displayName = "AlertDescription";

export { Alert, AlertTitle, AlertDescription };
