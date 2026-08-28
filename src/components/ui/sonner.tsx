import { Toaster as Sonner } from "sonner";

type ToasterProps = React.ComponentProps<typeof Sonner>;

const Toaster = ({ ...props }: ToasterProps) => {
  return (
    <Sonner
      className="toaster group"
      offset="max(4.75rem, calc(env(safe-area-inset-top) + 1.5rem))"
      toastOptions={{
        classNames: {
          toast:
            "group toast group-[.toaster]:bg-zinc-950/95 group-[.toaster]:backdrop-blur-xl group-[.toaster]:text-foreground group-[.toaster]:border-zinc-800 group-[.toaster]:shadow-2xl group-[.toaster]:rounded-2xl group-[.toaster]:p-3.5",
          description: "group-[.toast]:text-muted-foreground group-[.toast]:text-xs",
          actionButton: "group-[.toast]:bg-primary group-[.toast]:text-primary-foreground",
          cancelButton: "group-[.toast]:bg-muted group-[.toast]:text-muted-foreground",
        },
      }}
      {...props}
    />
  );
};

export { Toaster };
