from app.main import main


def test_main_returns_startup_message() -> None:
    assert main() == "Chief Site Engineer sistemi basladi."
