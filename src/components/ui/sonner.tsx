import { Toaster as Sonner } from "sonner";

type ToasterProps = React.ComponentProps<typeof Sonner>;

const Toaster = ({ ...props }: ToasterProps) => {
  return (
    <Sonner
      className="toaster group"
      visibleToasts={3}
      duration={4500}
      gap={8}
      offset="max(4.75rem, calc(env(safe-area-inset-top) + 1.5rem))"
      toastOptions={{
        classNames: {
          toast:
            "group toast group-[.toaster]:bg-zinc-950/95 group-[.toaster]:backdrop-blur-xl group-[.toaster]:text-foreground group-[.toaster]:border-zinc-800 group-[.toaster]:shadow-2xl group-[.toaster]:rounded-2xl group-[.toaster]:p-3.5",
          description: "group-[.toast]:text-muted-foreground group-[.toast]:text-xs",
          success: "group-[.toaster]:!border-l-4 group-[.toaster]:!border-l-emerald-400",
          error: "group-[.toaster]:!border-l-4 group-[.toaster]:!border-l-rose-500",
          warning: "group-[.toaster]:!border-l-4 group-[.toaster]:!border-l-amber-400",
          info: "group-[.toaster]:!border-l-4 group-[.toaster]:!border-l-sky-400",
          title: "group-[.toast]:!text-sm group-[.toast]:!font-bold group-[.toast]:!leading-snug",
          actionButton: "group-[.toast]:bg-primary group-[.toast]:text-primary-foreground",
          cancelButton: "group-[.toast]:bg-muted group-[.toast]:text-muted-foreground",
        },
      }}
      {...props}
    />
  );
};

export { Toaster };
