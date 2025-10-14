import tkinter as tk
from tkinter import ttk, messagebox
from sqlalchemy import create_engine, text
import pandas as pd


# Подключение
def get_engine(user, password, host, port, db):
    # pg8000 для подключения
    conn_str = f"postgresql+pg8000://{user}:{password}@{host}:{port}/{db}"
    return create_engine(conn_str, echo=False, future=True)


# Выполнение запроса
def execute_sql(query, engine):
    with engine.connect() as connection:
        return pd.read_sql_query(text(query), connection)


# Окно приложения
class DatabaseApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Database Connection System")
        self.geometry("900x650")
        self.configure(bg="#f8f9fa")
        self.engine = None
        self.role = None

        self.create_login_window()

    # для очистки окна
    def clear_window(self):
        for widget in self.winfo_children():
            widget.destroy()

    # Вход
    def create_login_window(self):
        self.clear_window()

        container = ttk.Frame(self)
        container.pack(expand=True)

        frame = ttk.LabelFrame(container, text="Подключение к базе данных")
        frame.pack(padx=20, pady=20)

        # Используемые поля
        labels = ["Host:", "Port:", "Database:", "User:", "Password:", "Role:"]
        defaults = ["localhost", "5432", "Touhou Project Records", "", "", ""]
        self.entries = []

        for i, label in enumerate(labels):
            ttk.Label(frame, text=label).grid(row=i, column=0, padx=10, pady=8, sticky="e")
            if label == "Password:":
                entry = ttk.Entry(frame, show="*")
            elif label == "Role:":
                self.role_var = tk.StringVar()
                entry = ttk.Combobox(frame, textvariable=self.role_var,
                                     values=["viewer", "moderator"], state="readonly", width=17)
                entry.current(0)
            else:
                entry = ttk.Entry(frame)
                if defaults[i]:
                    entry.insert(0, defaults[i])
            entry.grid(row=i, column=1, padx=10, pady=8)
            self.entries.append(entry)

        ttk.Button(frame, text="Подключиться", command=self.connect_db).grid(row=len(labels), column=0, columnspan=2, pady=15)

    # Соединение с БД
    def connect_db(self):
        try:
            host = self.entries[0].get()
            port = self.entries[1].get()
            db = self.entries[2].get()
            user = self.entries[3].get()
            password = self.entries[4].get()
            self.role = self.role_var.get()

            self.engine = get_engine(user, password, host, port, db)
            # Проверка подключения
            with self.engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            self.create_main_window()
        except Exception as e:
            messagebox.showerror("Ошибка подключения", str(e))

    # Окно после входа
    def create_main_window(self):
        self.clear_window()

        ttk.Label(self, text=f"Роль: {self.role.capitalize()}",
                  font=("Arial", 13, "bold")).pack(pady=10)

        # Окно поиска
        search_frame = ttk.LabelFrame(self, text="Поиск")
        search_frame.pack(padx=10, pady=10, fill="x")

        container = ttk.Frame(search_frame)
        container.pack(anchor="center", pady=10)

        ttk.Label(container, text="Введите значение:").grid(row=0, column=0, padx=5, pady=5)
        self.search_var = tk.StringVar()
        ttk.Entry(container, textvariable=self.search_var, width=40).grid(row=0, column=1, padx=5, pady=5)

        self.search_type = tk.StringVar(value="player")
        ttk.Radiobutton(container, text="По игроку", variable=self.search_type, value="player").grid(row=1, column=0, padx=10, pady=5)
        ttk.Radiobutton(container, text="По части", variable=self.search_type, value="game").grid(row=1, column=1, padx=10, pady=5)

        ttk.Button(container, text="Поиск", command=self.search_records).grid(row=2, column=0, columnspan=2, pady=10)

        # Окно вывода
        self.result_frame = ttk.LabelFrame(self, text="Результаты запроса")
        self.result_frame.pack(fill="both", expand=True, padx=10, pady=10)

        # Ввод запроса для модератора
        if self.role == "moderator":
            query_frame = ttk.LabelFrame(self, text="Или введите свой запрос")
            query_frame.pack(fill="x", padx=10, pady=10)

            self.query_text = tk.Text(query_frame, height=5)
            self.query_text.pack(fill="x", padx=5, pady=5)
            ttk.Button(query_frame, text="Выполнить", command=self.run_custom_query).pack(pady=5)

    # Поиск данных в дб
    def search_records(self):
        search_value = self.search_var.get().strip()
        mode = self.search_type.get()

        if not search_value:
            messagebox.showwarning("Внимание", "Введите значение для поиска!")
            return

        if mode == "player":
            query = f"SELECT * FROM player_records('{search_value}')"

        elif mode == "game":
            try:
                part = int(search_value)
                if part < 6 or part > 20 or part == 9:
                    raise ValueError
            except ValueError:
                messagebox.showerror("Ошибка", "Введите номер части(от 6 до 20, исключая 19)")
                return
            query = f"SELECT * FROM game_records('Touhou {part}')"

        else:
            messagebox.showerror("Ошибка", "Неверный режим поиска!")
            return

        try:
            df = execute_sql(query, self.engine)
            self.show_table(df)
        except Exception as e:
            messagebox.showerror("Ошибка выполнения", str(e))

    # Ручной ввод запроса
    def run_custom_query(self):
        query = self.query_text.get("1.0", tk.END).strip()
        if not query:
            messagebox.showwarning("Внимание", "Введите SQL-запрос!")
            return

        try:
            df = execute_sql(query, self.engine)
            self.show_table(df)
        except Exception as e:
            messagebox.showerror("Ошибка", str(e))

    # Вывод таблицы
    def show_table(self, df):
        for widget in self.result_frame.winfo_children():
            widget.destroy()

        if df.empty:
            ttk.Label(self.result_frame, text="Нет данных для отображения.").pack(pady=10)
            return

        table_frame = ttk.Frame(self.result_frame)
        table_frame.pack(expand=True, fill="both", pady=10)

        tree = ttk.Treeview(table_frame, columns=list(df.columns), show="headings")
        tree.pack(expand=True, fill="both")

        for col in df.columns:
            tree.heading(col, text=col)
            tree.column(col, anchor="center", width=150)

        for _, row in df.iterrows():
            tree.insert("", "end", values=list(row))

        # Скроллбар(пока что говно, может заменю)
        scrollbar_y = ttk.Scrollbar(table_frame, orient="vertical", command=tree.yview)
        tree.configure(yscrollcommand=scrollbar_y.set)
        scrollbar_y.pack(side="right", fill="y")


# Запуск приложения
if __name__ == "__main__":
    app = DatabaseApp()
    app.mainloop()
