param([string]$Root = "C:\Users\33660\Desktop\Storage\Personnel\NEW VAULT\1. NEW_VAULT")
# Utilise Windows PowerShell + assemblees WinForms explicites pour le raccourci global.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$formsAssembly=[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
$drawingAssembly=[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')
if(-not $formsAssembly){throw 'System.Windows.Forms est introuvable. Lancez le fichier avec Windows PowerShell 5.1, pas PowerShell 7.'}
Add-Type -ReferencedAssemblies $formsAssembly.Location,$drawingAssembly.Location @'
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
public class HotkeyForm : Form {
  [DllImport("user32.dll")] static extern bool RegisterHotKey(IntPtr hWnd, int id, uint modifiers, uint key);
  [DllImport("user32.dll")] static extern bool UnregisterHotKey(IntPtr hWnd, int id);
  public event EventHandler HotkeyPressed;
  protected override void OnHandleCreated(EventArgs e) { base.OnHandleCreated(e); RegisterHotKey(this.Handle, 4242, 0x0002, 0x4D); }
  protected override void WndProc(ref Message m) { if(m.Msg == 0x0312 && m.WParam.ToInt32() == 4242 && HotkeyPressed != null) HotkeyPressed(this, EventArgs.Empty); base.WndProc(ref m); }
  protected override void OnHandleDestroyed(EventArgs e) { UnregisterHotKey(this.Handle, 4242); base.OnHandleDestroyed(e); }
}
'@
[Windows.Forms.Application]::EnableVisualStyles()
$preferred='C:\Users\33660\Desktop\Storage\Personnel\NEW VAULT\1. NEW_VAULT'
$script:rootPath=if(Test-Path -LiteralPath $Root -PathType Container){(Resolve-Path -LiteralPath $Root).Path}elseif(Test-Path -LiteralPath $preferred -PathType Container){(Resolve-Path -LiteralPath $preferred).Path}else{[Environment]::GetFolderPath('UserProfile')}
$script:selected=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase);$script:nodes=@{};$script:hydrating=$false
$form=New-Object HotkeyForm;$form.Text='File Picker — documents';$form.Size=New-Object Drawing.Size(1000,720);$form.MinimumSize=New-Object Drawing.Size(760,560);$form.StartPosition='CenterScreen';$form.BackColor=[Drawing.Color]::FromArgb(247,249,252);$form.Font=New-Object Drawing.Font('Segoe UI',9);$form.ShowInTaskbar=$true
$header=New-Object Windows.Forms.Panel;$header.Dock='Top';$header.Height=112;$header.BackColor=[Drawing.Color]::FromArgb(24,54,86);$form.Controls.Add($header)
$title=New-Object Windows.Forms.Label;$title.Text='Sélectionner des documents';$title.ForeColor=[Drawing.Color]::White;$title.Font=New-Object Drawing.Font('Segoe UI Semibold',20);$title.Location=New-Object Drawing.Point(28,16);$title.AutoSize=$true;$header.Controls.Add($title)
$sub=New-Object Windows.Forms.Label;$sub.Text='Ctrl+M pour afficher cette fenêtre à tout moment';$sub.ForeColor=[Drawing.Color]::FromArgb(210,225,241);$sub.Location=New-Object Drawing.Point(30,57);$sub.AutoSize=$true;$header.Controls.Add($sub)
$search=New-Object Windows.Forms.TextBox;$search.Location=New-Object Drawing.Point(28,130);$search.Size=New-Object Drawing.Size(560,29);$search.Anchor='Top,Left,Right';$form.Controls.Add($search)
$refresh=New-Object Windows.Forms.Button;$refresh.Text='Rafraîchir';$refresh.Location=New-Object Drawing.Point(610,130);$refresh.Size=New-Object Drawing.Size(150,29);$refresh.Anchor='Top,Right';$form.Controls.Add($refresh)
$change=New-Object Windows.Forms.Button;$change.Text='Changer de dossier';$change.Location=New-Object Drawing.Point(780,130);$change.Size=New-Object Drawing.Size(160,29);$change.Anchor='Top,Right';$form.Controls.Add($change)
$path=New-Object Windows.Forms.Label;$path.ForeColor=[Drawing.Color]::FromArgb(75,88,104);$path.Location=New-Object Drawing.Point(30,170);$path.AutoSize=$true;$form.Controls.Add($path)
$tree=New-Object Windows.Forms.TreeView;$tree.Location=New-Object Drawing.Point(28,200);$tree.Size=New-Object Drawing.Size(912,375);$tree.Anchor='Top,Bottom,Left,Right';$tree.CheckBoxes=$true;$tree.ShowLines=$true;$tree.ShowPlusMinus=$true;$tree.FullRowSelect=$true;$tree.HideSelection=$false;$tree.BackColor=[Drawing.Color]::White;$tree.Font=New-Object Drawing.Font('Segoe UI',10);$form.Controls.Add($tree)
$count=New-Object Windows.Forms.Label;$count.Location=New-Object Drawing.Point(30,603);$count.AutoSize=$true;$count.Anchor='Bottom,Left';$count.Font=New-Object Drawing.Font('Segoe UI Semibold',10);$form.Controls.Add($count)
$status=New-Object Windows.Forms.Label;$status.ForeColor=[Drawing.Color]::FromArgb(75,88,104);$status.Location=New-Object Drawing.Point(250,603);$status.AutoSize=$true;$status.Anchor='Bottom,Left';$form.Controls.Add($status)
$all=New-Object Windows.Forms.Button;$all.Text='Tout sélectionner';$all.Location=New-Object Drawing.Point(570,595);$all.Size=New-Object Drawing.Size(125,34);$all.Anchor='Bottom,Right';$form.Controls.Add($all)
$none=New-Object Windows.Forms.Button;$none.Text='Tout désélectionner';$none.Location=New-Object Drawing.Point(705,595);$none.Size=New-Object Drawing.Size(145,34);$none.Anchor='Bottom,Right';$form.Controls.Add($none)
$copy=New-Object Windows.Forms.Button;$copy.Text='Copier les fichiers';$copy.Location=New-Object Drawing.Point(860,595);$copy.Size=New-Object Drawing.Size(120,34);$copy.Anchor='Bottom,Right';$copy.BackColor=[Drawing.Color]::FromArgb(35,105,190);$copy.ForeColor=[Drawing.Color]::White;$copy.FlatStyle='Flat';$form.Controls.Add($copy)
$tray=New-Object Windows.Forms.NotifyIcon;$tray.Icon=[Drawing.SystemIcons]::Application;$tray.Text='File Picker — Ctrl+M';$tray.Visible=$true;$menu=New-Object Windows.Forms.ContextMenuStrip;$show=$menu.Items.Add('Afficher (Ctrl+M)');$quit=$menu.Items.Add('Quitter');$tray.ContextMenuStrip=$menu
function Is-Doc($x){$x.Extension.ToLowerInvariant() -in @('.md','.pdf','.txt','.html','.htm','.png','.jpg','.jpeg','.gif','.webp','.svg','.csv','.json','.xml','.doc','.docx','.rtf','.epub','.tex','.log','.mp4','.mov','.avi','.mkv','.webm','.wmv','.m4v','.mpeg','.mpg','.3gp','.mp3','.wav','.flac','.aac','.m4a','.ogg','.wma','.opus','.xls','.xlsx','.xlsm','.ods','.ppt','.pptx','.odp','.key')}
function Update-Count{$count.Text="$($script:selected.Count) fichier$(if($script:selected.Count -ne 1){'s'}) sélectionné$(if($script:selected.Count -ne 1){'s'})"}
function Set-Subtree($n,[bool]$v){foreach($c in $n.Nodes){$c.Checked=$v;Set-Subtree $c $v}}
function New-LazyNode{$n=New-Object Windows.Forms.TreeNode('Chargement…');$n.Tag='__LAZY__';$n}
function Add-LazyChildren($node){if($node.Nodes.Count -ne 1 -or $node.Nodes[0].Tag -ne '__LAZY__'){return};$node.Nodes.Clear();$dir=Get-Item -LiteralPath ([string]$node.Tag) -ErrorAction SilentlyContinue;if(!$dir){return};foreach($item in @(Get-ChildItem -LiteralPath $dir.FullName -Force -ErrorAction SilentlyContinue|Where-Object{$_.Name -notlike '.*'}|Sort-Object @{Expression={$_.PSIsContainer};Descending=$true},Name)){if($item.PSIsContainer){$d=New-Object Windows.Forms.TreeNode($item.Name);$d.Tag=$item.FullName;[void]$d.Nodes.Add((New-LazyNode));[void]$node.Nodes.Add($d)}elseif((Is-Doc $item)-and($item.BaseName -ine $dir.Name)){$f=New-Object Windows.Forms.TreeNode($item.Name);$f.Tag=$item.FullName;$script:nodes[$item.FullName]=$f;[void]$node.Nodes.Add($f)}}}
function Load-AllChildren($node){Add-LazyChildren $node;foreach($child in @($node.Nodes)){if($child.Tag -ne '__LAZY__' -and $child.Nodes.Count -gt 0){Load-AllChildren $child}};$node.Expand()}
function Set-FolderSelection($node,[bool]$value){$script:hydrating=$true;try{Load-AllChildren $node;$node.Checked=$value;Set-Subtree $node $value;foreach($f in $script:nodes.Values){if($f.Checked){[void]$script:selected.Add([string]$f.Tag)}else{[void]$script:selected.Remove([string]$f.Tag)}}}finally{$script:hydrating=$false};Update-Count}
function Add-Root{$tree.Nodes.Clear();$script:nodes=@{};$r=New-Object Windows.Forms.TreeNode((Split-Path $script:rootPath -Leaf));$r.Tag=$script:rootPath;[void]$r.Nodes.Add((New-LazyNode));[void]$tree.Nodes.Add($r);$r.Expand();$path.Text=$script:rootPath;$status.Text='Ctrl+M affiche la fenêtre; fermer la masque.';Update-Count}
$tree.Add_BeforeExpand({param($s,$e)Add-LazyChildren $e.Node})
$tree.Add_AfterCheck({param($s,$e)if($script:hydrating -or $e.Node.Tag -eq '__LAZY__'){return};if($e.Node.Nodes.Count -gt 0){Set-FolderSelection $e.Node $e.Node.Checked;return};if($e.Node.Checked){[void]$script:selected.Add([string]$e.Node.Tag)}else{[void]$script:selected.Remove([string]$e.Node.Tag)};Update-Count})
$all.Add_Click({foreach($n in $script:nodes.Values){$n.Checked=$true;[void]$script:selected.Add([string]$n.Tag)};Update-Count});$none.Add_Click({foreach($n in $script:nodes.Values){$n.Checked=$false};$script:selected.Clear();Update-Count})
$refresh.Add_Click({$tree.BeginUpdate();try{Add-Root}catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Erreur de rafraîchissement')}finally{$tree.EndUpdate()}})
$change.Add_Click({$d=New-Object Windows.Forms.FolderBrowserDialog;if($d.ShowDialog() -eq 'OK'){$script:rootPath=$d.SelectedPath;Add-Root}})
$copy.Add_Click({if(!$script:selected.Count){[Windows.Forms.MessageBox]::Show('Cochez au moins un fichier.','Aucun fichier');return};$st=Join-Path $env:TEMP 'document-picker';Remove-Item $st -Recurse -Force -ErrorAction SilentlyContinue;New-Item $st -ItemType Directory -Force|Out-Null;$list=New-Object Collections.Specialized.StringCollection;$base=(Resolve-Path -LiteralPath $script:rootPath).Path.TrimEnd('\');foreach($src in $script:selected){$full=(Resolve-Path -LiteralPath $src).Path;$relative=$full.Substring($base.Length).TrimStart('\');$parts=@((Split-Path $base -Leaf)+$(if($relative){$relative -split '\\'}else{@()}));$safeParts=@($parts|ForEach-Object{$_ -replace '[<>:"/\\|?*]','_'});$name=[string]::Join('.', $safeParts);$dst=Join-Path $st $name;Copy-Item -LiteralPath $src -Destination $dst -Force;[void]$list.Add($dst)};[Windows.Forms.Clipboard]::SetFileDropList($list)})
function Show-Picker{$form.Show();$form.WindowState='Normal';$form.Activate();$form.BringToFront()}
$handler=[EventHandler]{Show-Picker};$form.add_HotkeyPressed($handler);$show.Add_Click($handler)
$form.Add_FormClosing({param($s,$e)if(!$script:quitting){$e.Cancel=$true;$form.Hide()}});$quit.Add_Click({$script:quitting=$true;$tray.Visible=$false;$form.Close()})
Add-Root;$form.Hide();[Windows.Forms.Application]::Run($form);$tray.Dispose()
