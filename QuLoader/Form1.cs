using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Text;
using System.Windows.Forms;

namespace QuLoader
{
    public partial class Form1 : Form
    {
        public Form1() => InitializeComponent();
        private async void guna2Button18_Click(object sender, EventArgs e)
        {
            string fileUrl = "https://github.com/QUANTUMLOADER123/-/raw/main/free_quantum.exe";
            string documentsPath = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
            string quLoaderPath = Path.Combine(documentsPath, "QuLoader");
            string localFilePath = Path.Combine(quLoaderPath, "free_quantum.exe");

            try
            {
                if (!Directory.Exists(quLoaderPath))
                    Directory.CreateDirectory(quLoaderPath);

                if (File.Exists(localFilePath))
                    File.Delete(localFilePath);

                using (WebClient webClient = new WebClient())
                    await webClient.DownloadFileTaskAsync(fileUrl, localFilePath);

                if (File.Exists(localFilePath))
                    Process.Start(localFilePath);
                else
                    MessageBox.Show("Файл не был скачан.");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка: {ex.Message}");
            }
        }

        private void guna2Button3_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.BringToFront();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button4_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.BringToFront();
            guna2Panel9.SendToBack();
            guna2Panel1.SendToBack();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button6_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.BringToFront();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.SendToBack();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button2_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }

        private void guna2Button1_Click(object sender, EventArgs e)
        {
            Hide();
        }

        private void guna2Button13_Click(object sender, EventArgs e)
        {

        }

        private void guna2Button5_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/quantum_standoff2");
        }

        private void guna2Button16_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.BringToFront();
            guna2Panel1.SendToBack();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button17_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.BringToFront();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button15_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.BringToFront();
            guna2Panel1.SendToBack();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button7_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.SendToBack();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.BringToFront();
        }

        private void guna2Button54_Click(object sender, EventArgs e)
        {
            MessageBox.Show("В разработке.");
        }

        private void guna2Button32_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/amyr_softikk");
        }

        private void guna2Button63_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/gtr_win");
        }

        private void guna2Button58_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/gtr_win");
        }

        private void guna2Button51_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/powergirlso2");
        }

        private void guna2Button19_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/quantum_standoff2");
        }

        private void guna2Button27_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/arcanorev");
        }

        private void guna2Button46_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/quantum_standoff2");
        }

        private void guna2Button42_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/astralcustom");
        }

        private async void guna2Button28_Click(object sender, EventArgs e)
        {
            string fileUrl = "https://github.com/QUANTUMLOADER123/-/raw/main/AmyrPrivate%20cracked%20by%20%40ArcanoRev.exe";
            string documentsPath = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
            string quLoaderPath = Path.Combine(documentsPath, "QuLoader");
            string localFilePath = Path.Combine(quLoaderPath, "AmyrPrivate cracked by @ArcanoRev.exe");

            try
            {
                if (!Directory.Exists(quLoaderPath))
                    Directory.CreateDirectory(quLoaderPath);

                if (File.Exists(localFilePath))
                    File.Delete(localFilePath);

                using (WebClient webClient = new WebClient())
                    await webClient.DownloadFileTaskAsync(fileUrl, localFilePath);

                if (File.Exists(localFilePath))
                    Process.Start(localFilePath);
                else
                    MessageBox.Show("Файл не был скачан.");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка: {ex.Message}");
            }
        }

        private async void guna2Button47_Click(object sender, EventArgs e)
        {
            string fileUrl = "https://github.com/QUANTUMLOADER123/-/raw/main/quantumfree.exe";
            string documentsPath = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
            string quLoaderPath = Path.Combine(documentsPath, "QuLoader");
            string localFilePath = Path.Combine(quLoaderPath, "quantumfree.exe");

            try
            {
                if (!Directory.Exists(quLoaderPath))
                    Directory.CreateDirectory(quLoaderPath);

                if (File.Exists(localFilePath))
                    File.Delete(localFilePath);

                using (WebClient webClient = new WebClient())
                    await webClient.DownloadFileTaskAsync(fileUrl, localFilePath);

                if (File.Exists(localFilePath))
                    Process.Start(localFilePath);
                else
                    MessageBox.Show("Файл не был скачан.");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка: {ex.Message}");
            }
        }

        private void guna2Button59_Click(object sender, EventArgs e)
        {
            MessageBox.Show("Файл слишком большой, скачайте его сами в телеграмм!");
            System.Diagnostics.Process.Start("https://t.me/gtr_win");
        }

        private async void guna2Button52_Click(object sender, EventArgs e)
        {
            string fileUrl = "https://github.com/QUANTUMLOADER123/-/raw/main/powercheat%20free.rar";
            string documentsPath = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
            string quLoaderPath = Path.Combine(documentsPath, "QuLoader");
            string localFilePath = Path.Combine(quLoaderPath, "powercheat%20free.rar");

            try
            {
                if (!Directory.Exists(quLoaderPath))
                    Directory.CreateDirectory(quLoaderPath);

                if (File.Exists(localFilePath))
                    File.Delete(localFilePath);

                using (WebClient webClient = new WebClient())
                    await webClient.DownloadFileTaskAsync(fileUrl, localFilePath);

                if (File.Exists(localFilePath))
                    Process.Start(localFilePath);
                else
                    MessageBox.Show("Файл не был скачан.");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка: {ex.Message}");
            }
        }

        private async void guna2Button43_Click(object sender, EventArgs e)
        {
            string fileUrl = "https://github.com/QUANTUMLOADER123/-/raw/main/AstraL%20Fix%20Sens.exe";
            string documentsPath = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
            string quLoaderPath = Path.Combine(documentsPath, "QuLoader");
            string localFilePath = Path.Combine(quLoaderPath, "AstraL Fix Sens.exe");

            try
            {
                if (!Directory.Exists(quLoaderPath))
                    Directory.CreateDirectory(quLoaderPath);

                if (File.Exists(localFilePath))
                    File.Delete(localFilePath);

                using (WebClient webClient = new WebClient())
                    await webClient.DownloadFileTaskAsync(fileUrl, localFilePath);

                if (File.Exists(localFilePath))
                    Process.Start(localFilePath);
                else
                    MessageBox.Show("Файл не был скачан.");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка: {ex.Message}");
            }
        }

        private async void guna2Button33_Click(object sender, EventArgs e)
        {
            string fileUrl = "https://github.com/QUANTUMLOADER123/-/raw/main/AmyrFree.exe";
            string documentsPath = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
            string quLoaderPath = Path.Combine(documentsPath, "QuLoader");
            string localFilePath = Path.Combine(quLoaderPath, "AmyrFree.exe");

            try
            {
                if (!Directory.Exists(quLoaderPath))
                    Directory.CreateDirectory(quLoaderPath);

                if (File.Exists(localFilePath))
                    File.Delete(localFilePath);

                using (WebClient webClient = new WebClient())
                    await webClient.DownloadFileTaskAsync(fileUrl, localFilePath);

                if (File.Exists(localFilePath))
                    Process.Start(localFilePath);
                else
                    MessageBox.Show("Файл не был скачан.");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка: {ex.Message}");
            }
        }

        private void guna2Button35_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/c/2274752226/1163");
        }

        private async void guna2Button64_Click(object sender, EventArgs e)
        {
            string fileUrl = "https://github.com/QUANTUMLOADER123/-/raw/main/WIN.exe";
            string documentsPath = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
            string quLoaderPath = Path.Combine(documentsPath, "QuLoader");
            string localFilePath = Path.Combine(quLoaderPath, "WIN.exe");

            try
            {
                if (!Directory.Exists(quLoaderPath))
                    Directory.CreateDirectory(quLoaderPath);

                if (File.Exists(localFilePath))
                    File.Delete(localFilePath);

                using (WebClient webClient = new WebClient())
                    await webClient.DownloadFileTaskAsync(fileUrl, localFilePath);

                if (File.Exists(localFilePath))
                    Process.Start(localFilePath);
                else
                    MessageBox.Show("Файл не был скачан.");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка: {ex.Message}");
            }
        }

        private void guna2Button8_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.SendToBack();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.BringToFront();
            guna2Panel7.SendToBack();
        }

        private void guna2Button9_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.SendToBack();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.BringToFront();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button14_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.SendToBack();
            guna2Panel27.SendToBack();
            guna2Panel20.BringToFront();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button10_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.SendToBack();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.BringToFront();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button12_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.SendToBack();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.BringToFront();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button55_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.SendToBack();
            guna2Panel27.BringToFront();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button53_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.BringToFront();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button29_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.BringToFront();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button48_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.BringToFront();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button44_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.BringToFront();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button34_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.BringToFront();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button65_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.BringToFront();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button60_Click(object sender, EventArgs e)
        {
            /*guna2Panel3 квантум
guna2Panel2 кска
guna2Panel9 разделы
guna2Panel1 станок
guna2Panel7 амур кряк
guna2Panel12 амур фри
guna2Panel16 фикс сенс
guna2Panel24 гтр ченжер
guna2Panel21 поверчет
guna2Panel20 квантум сч
guna2Panel27 фри гтр вин*/
            //guna2Panel9.SendToBack();
            //guna2Panel9.SendToBack();
            //guna2Panel1.BringToFront();

            guna2Panel3.SendToBack();
            guna2Panel2.SendToBack();
            guna2Panel9.SendToBack();
            guna2Panel1.BringToFront();
            guna2Panel27.SendToBack();
            guna2Panel20.SendToBack();
            guna2Panel21.SendToBack();
            guna2Panel24.SendToBack();
            guna2Panel16.SendToBack();
            guna2Panel12.SendToBack();
            guna2Panel7.SendToBack();
        }

        private void guna2Button74_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/powergirlso2/4416");
        }

        private void guna2Button75_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/c/2396780505/1419");
        }

        private void guna2Button76_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/ArcanoRev/142");
        }

        private void guna2Button77_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/c/2396780505/1283");
        }

        private void guna2Button78_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/astralcustom/675");
        }

        private void guna2Button79_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/GTR_WIN/4270");
        }

        private void guna2Button80_Click(object sender, EventArgs e)
        {
            System.Diagnostics.Process.Start("https://t.me/GTR_WIN/4207");
        }
    }
}