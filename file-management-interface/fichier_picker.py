from __future__ import annotations

import shutil
import sys
import tempfile
from pathlib import Path

from PySide6.QtCore import QMimeData, QUrl, Qt
from PySide6.QtGui import QAction, QFont
from PySide6.QtWidgets import (
    QApplication, QCheckBox, QFileDialog, QHBoxLayout, QLabel, QListWidget,
    QListWidgetItem, QMainWindow, QMessageBox, QPushButton, QVBoxLayout, QWidget,
)

EXTENSIONS = {".md", ".pdf"}


def eligible(path: Path) -> bool:
    return path.suffix.lower() in EXTENSIONS and path.stem.casefold() != path.parent.name.casefold()


def set_file_clipboard(paths: list[Path]) -> None:
    mime = QMimeData()
    mime.setUrls([QUrl.fromLocalFile(str(path.resolve())) for path in paths])
    QApplication.clipboard().setMimeData(mime)


class Picker(QMainWindow):
    def __init__(self, root_path: Path):
        super().__init__()
        self.root_path = root_path
        self.staging = Path(tempfile.mkdtemp(prefix="document-picker-"))
        self.setWindowTitle("Sélecteur de documents")
        self.resize(900, 650)
        self.setMinimumSize(680, 480)
        self.build_ui()
        self.populate()

    def build_ui(self):
        central = QWidget()
        central.setObjectName("central")
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        layout.setContentsMargins(24, 20, 24, 20)
        layout.setSpacing(12)

        eyebrow = QLabel("SÉLECTEUR DE DOCUMENTS")
        eyebrow.setObjectName("eyebrow")
        layout.addWidget(eyebrow)
        title = QLabel("Choisissez les fichiers à copier")
        title.setObjectName("title")
        layout.addWidget(title)
        subtitle = QLabel("Les .md et .pdf dont le nom diffère de leur dossier sont proposés.")
        subtitle.setObjectName("subtitle")
        layout.addWidget(subtitle)

        path_row = QHBoxLayout()
        self.path_label = QLabel(str(self.root_path))
        self.path_label.setObjectName("path")
        self.path_label.setTextInteractionFlags(Qt.TextSelectableByMouse)
        path_row.addWidget(self.path_label, 1)
        change = QPushButton("Changer de dossier")
        change.clicked.connect(self.choose_root)
        path_row.addWidget(change)
        layout.addLayout(path_row)

        actions = QHBoxLayout()
        all_on = QPushButton("Tout cocher")
        all_on.clicked.connect(lambda: self.set_all(True))
        actions.addWidget(all_on)
        all_off = QPushButton("Tout décocher")
        all_off.clicked.connect(lambda: self.set_all(False))
        actions.addWidget(all_off)
        actions.addStretch()
        self.count = QLabel("0 fichier sélectionné")
        self.count.setObjectName("count")
        actions.addWidget(self.count)
        layout.addLayout(actions)

        self.list = QListWidget()
        self.list.setSelectionMode(QListWidget.NoSelection)
        self.list.itemChanged.connect(self.update_count)
        layout.addWidget(self.list, 1)

        footer = QHBoxLayout()
        footer.addStretch()
        validate = QPushButton("Valider et copier")
        validate.setObjectName("primary")
        validate.clicked.connect(self.validate)
        footer.addWidget(validate)
        layout.addLayout(footer)

        central.setStyleSheet("""
            QWidget#central { background: #f3f6fa; }
            QLabel#eyebrow { color: #1e5aa8; font-size: 11px; font-weight: 700; letter-spacing: 1px; }
            QLabel#title { color: #172033; font-size: 25px; font-weight: 700; }
            QLabel#subtitle, QLabel#count { color: #596579; font-size: 13px; }
            QLabel#path { background: #e5ebf3; color: #29384d; padding: 11px; border-radius: 5px; }
            QPushButton { background: #dce8f5; color: #164d8c; border: 0; border-radius: 5px; padding: 10px 14px; font-weight: 600; }
            QPushButton:hover { background: #c8dcf1; }
            QPushButton#primary { background: #1e5aa8; color: white; padding: 11px 22px; }
            QPushButton#primary:hover { background: #174a8b; }
            QListWidget { background: white; border: 1px solid #d6dee9; border-radius: 5px; padding: 8px; color: #29384d; }
            QListWidget::item { padding: 5px; }
        """)

    def populate(self):
        self.list.clear()
        folders = sorted([p for p in self.root_path.rglob("*") if p.is_dir()], key=lambda p: str(p).casefold())
        files = sorted([p for p in self.root_path.rglob("*") if p.is_file() and eligible(p)], key=lambda p: str(p).casefold())
        for folder in [self.root_path, *folders]:
            children = [p for p in files if p.parent == folder]
            if not children:
                continue
            relative = folder.relative_to(self.root_path) if folder != self.root_path else Path(".")
            header = QListWidgetItem(f"▾  {relative}")
            header.setFlags(Qt.ItemIsEnabled)
            font = QFont(); font.setBold(True); header.setFont(font)
            self.list.addItem(header)
            for path in children:
                item = QListWidgetItem(f"  {path.name}")
                item.setData(Qt.UserRole, str(path))
                item.setFlags(Qt.ItemIsEnabled | Qt.ItemIsUserCheckable)
                item.setCheckState(Qt.Unchecked)
                self.list.addItem(item)
        self.update_count()

    def update_count(self):
        n = sum(self.list.item(i).checkState() == Qt.Checked for i in range(self.list.count()))
        self.count.setText(f"{n} fichier{'s' if n != 1 else ''} sélectionné{'s' if n != 1 else ''}")

    def set_all(self, value: bool):
        state = Qt.Checked if value else Qt.Unchecked
        for i in range(self.list.count()):
            item = self.list.item(i)
            if item.flags() & Qt.ItemIsUserCheckable:
                item.setCheckState(state)

    def choose_root(self):
        chosen = QFileDialog.getExistingDirectory(self, "Choisir le dossier racine", str(self.root_path))
        if chosen:
            self.root_path = Path(chosen)
            self.path_label.setText(str(self.root_path))
            self.populate()

    def validate(self):
        selected = [Path(self.list.item(i).data(Qt.UserRole)) for i in range(self.list.count()) if self.list.item(i).checkState() == Qt.Checked]
        if not selected:
            QMessageBox.warning(self, "Aucun fichier", "Cochez au moins un fichier avant de valider.")
            return
        try:
            shutil.rmtree(self.staging, ignore_errors=True)
            self.staging.mkdir()
            copies = []
            for source in selected:
                destination = self.staging / source.name
                if destination.exists():
                    destination = self.staging / f"{source.stem} - {source.parent.name}{source.suffix}"
                shutil.copy2(source, destination)
                copies.append(destination)
            set_file_clipboard(copies)
            QMessageBox.information(self, "Copié", f"{len(copies)} fichier(s) sont prêts. Utilisez Ctrl+V à l'endroit souhaité.")
        except Exception as exc:
            QMessageBox.critical(self, "Erreur", str(exc))


if __name__ == "__main__":
    app = QApplication(sys.argv)
    initial = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.home()
    window = Picker(initial if initial.is_dir() else Path.home())
    window.show()
    sys.exit(app.exec())
