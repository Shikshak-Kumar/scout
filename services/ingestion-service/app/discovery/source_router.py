class SourceRouter:
    """
    Decides which strategy should be used
    for a particular source.
    """

    API_SOURCES = {
        "greenhouse",
        "lever",
        "ashby",
    }

    @classmethod
    def get_strategy(cls, source: str) -> str:

        source = source.lower()

        if source in cls.API_SOURCES:
            return "api"

        if source in {
            "linkedin",
            "indeed",
        }:
            return "serper"

        return "serper"