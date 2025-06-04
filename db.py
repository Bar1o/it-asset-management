import sqlite3


def init_db(db_path="local.db", schema_path="makedb.sql"):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    with open(schema_path, "r", encoding="utf-8") as f:
        ddl = f.read()
    cur.executescript(ddl)

    conn.commit()
    conn.close()


if __name__ == "__main__":
    init_db()
    print("БД local.db создана и схема загружена")
