const files = [
  { name: 'fichier_picker.py', type: 'Python', detail: 'Interface + filtre + presse-papiers' },
  { name: 'lancer_picker.bat', type: 'Windows', detail: 'Lancement en un double-clic' },
  { name: 'README_WINDOWS.txt', type: 'Guide', detail: 'Installation et dépannage' },
]

export default function Page() {
  return (
    <main className="min-h-screen bg-background text-foreground">
      <div className="mx-auto flex min-h-screen max-w-6xl flex-col px-6 py-8 md:px-10 md:py-12">
        <header className="flex items-center justify-between border-b border-border pb-6">
          <div className="flex items-center gap-3"><span className="grid size-9 place-items-center rounded-lg bg-primary text-primary-foreground font-mono text-sm font-bold">FP</span><span className="font-mono text-sm font-semibold tracking-tight">file_picker / windows</span></div>
          <span className="rounded-full border border-border bg-card px-3 py-1 font-mono text-xs text-muted-foreground">v1.0 · offline</span>
        </header>
        <section className="grid flex-1 items-center gap-12 py-16 lg:grid-cols-[1.15fr_.85fr] lg:gap-20">
          <div>
            <p className="mb-5 font-mono text-sm font-medium text-primary">NATIVE WINDOWS UTILITY</p>
            <h1 className="max-w-3xl text-pretty text-5xl font-bold leading-[1.04] tracking-[-0.04em] md:text-7xl">Sélectionner. Copier. Continuer.</h1>
            <p className="mt-7 max-w-xl text-pretty text-lg leading-8 text-muted-foreground">Un faux explorateur Windows 11 pour rassembler vos documents Markdown et PDF en quelques clics, sans modifier les originaux.</p>
            <div className="mt-9 flex flex-wrap gap-3"><a href="#installation" className="rounded-lg bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground transition hover:opacity-90">Voir l’installation</a><a href="#regle" className="rounded-lg border border-border bg-card px-5 py-3 text-sm font-semibold transition hover:bg-accent">Comprendre le filtre</a></div>
          </div>
          <div className="relative overflow-hidden rounded-2xl border border-border bg-card p-5 shadow-sm md:p-7"><div className="mb-5 flex items-center justify-between"><span className="font-mono text-xs text-muted-foreground">DELIVERABLES</span><span className="size-2 rounded-full bg-primary" /></div><div className="space-y-2">{files.map((file) => <div key={file.name} className="flex items-center gap-4 rounded-xl border border-border bg-background p-4"><div className="grid size-10 shrink-0 place-items-center rounded-lg bg-accent font-mono text-xs font-bold text-primary">{file.type.slice(0, 2).toUpperCase()}</div><div className="min-w-0"><p className="truncate font-mono text-sm font-semibold">{file.name}</p><p className="mt-1 text-xs text-muted-foreground">{file.detail}</p></div></div>)}</div><div className="mt-5 rounded-xl bg-primary p-4 text-primary-foreground"><p className="font-mono text-xs opacity-75">READY STATE</p><p className="mt-1 text-sm font-medium">Ctrl+V après validation</p></div></div>
        </section>
        <section id="regle" className="grid gap-4 border-t border-border py-12 md:grid-cols-3"><div><p className="font-mono text-xs text-primary">01 / FILTRER</p><h2 className="mt-3 text-xl font-semibold">Seulement l’utile</h2><p className="mt-2 text-sm leading-6 text-muted-foreground">Les extensions .md et .pdf sont détectées récursivement.</p></div><div><p className="font-mono text-xs text-primary">02 / DÉCIDER</p><h2 className="mt-3 text-xl font-semibold">Une règle claire</h2><p className="mt-2 text-sm leading-6 text-muted-foreground">cours/cours.md est ignoré. cours/terminal.md est conservé. La comparaison ignore les majuscules.</p></div><div><p className="font-mono text-xs text-primary">03 / COLLER</p><h2 className="mt-3 text-xl font-semibold">Prêt pour Ctrl+V</h2><p className="mt-2 text-sm leading-6 text-muted-foreground">Les copies sont déposées dans le presse-papiers Windows sans toucher aux fichiers source.</p></div></section>
        <section id="installation" className="border-t border-border py-12"><div className="grid gap-8 md:grid-cols-[.7fr_1.3fr] md:items-start"><div><p className="font-mono text-xs text-primary">INSTALLATION</p><h2 className="mt-3 text-3xl font-bold tracking-tight">Deux fichiers à lancer</h2></div><div className="rounded-2xl border border-border bg-card p-6"><ol className="space-y-4 text-sm leading-6"><li><span className="mr-3 font-mono text-primary">01</span>Installer Python 3 depuis python.org avec l’option PATH.</li><li><span className="mr-3 font-mono text-primary">02</span>Double-cliquer sur <code className="rounded bg-accent px-1.5 py-0.5 font-mono text-xs">lancer_picker.bat</code>.</li><li><span className="mr-3 font-mono text-primary">03</span>Choisir un dossier, cocher les fichiers, puis valider.</li></ol><p className="mt-6 border-t border-border pt-5 text-xs leading-5 text-muted-foreground">Le guide complet est dans README_WINDOWS.txt. Tkinter est inclus dans l’installation standard de Python.</p></div></div></section>
        <footer className="flex flex-wrap justify-between gap-3 border-t border-border pt-6 font-mono text-xs text-muted-foreground"><span>Conçu pour Windows 11</span><span>Python standard library · aucune dépendance externe</span></footer>
      </div>
    </main>
  )
}
