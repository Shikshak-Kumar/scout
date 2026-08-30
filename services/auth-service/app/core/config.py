import os
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict

DEV_PRIVATE_KEY = """-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAtPxP6pkLWjmG0GKxA+Ls7XNEr6TecUQ6JeeqWNqguSQv6C10
mq3Baz94UA/TQFqPlV6uLFrPlA/gC503CE+91vMWosvYUn844TWqGqsoCHvyLlhu
sJCgt9UWf0C42n5SLtqezV/Ej+LtbgOmU3/CmokVmFrlpsMH0c07U2dCST998rG8
UqQ8id1Zuq5mkTSa5xLGcH2/wMPJhpU2v+MJ/7wmm/6DaU5T/qm4n2BjfOWZZ4Wz
h3TOmkSTUPU0XXT8PzVEOF4l57srSgn9FjFq5RtqIXPNH4KVhb6FL2w0TXjAdQ3Y
WAzvgB9fqZEe3EFsV/Yoic6qZfZRI89L7XMSawIDAQABAoIBAEepuIMuAn7BVI5i
5bCiRCppgAMEh0fWOigUKTFxsD5fA9EtXoR41KOAyET7XyyWL1B34wORGayI9K/k
movh90uLiaUAjjFsSrtyIl7Y8ssZOPX88idbvSfNalEM8aUia6w9yK+NgilvM5Bi
RZO+fPHv4esn4tM7WndKinkl4+tYW+5usi/rp4KccgiTtsKOHyrskSfi95QwgDiv
gGd0JFx7LpFiBTIpbjBCY2UoSK4NCL8qG8zXAW/Hd7oMVUHL9LXed/shGzeo9WkZ
F83gb/cM6OpS/3enw3NLvkMLBQXutms2LoPIHoy4atoTqhrEaDweZQ12zyfekEiY
UnGYy8ECgYEA45Ug4HCBU065GLfU6pyNah61HTYfGjJ+yW8HB12c90dBTWmfmiF/
9y9DDbVa+wQpurax/9R9mxQtr+VD6BLi+QNQc2FCL3ofTr2pHPD2d7Pq/p25avv9
cA4gW1fHMI/hPBvC3jPPuyo5JH/7YPM+nt4kKytU1zAf06KlJq5pRVECgYEAy5Ws
KNNC5j/HVny+2tsDyZA8ZSJqfXjhk1jOW1pqawbujlWpkJdaL/djeYinzzQngqCe
t3paAfQixVY5uEYPVYzf9q/V1n8+9f/0CNvuFR0OP12mR8DCD/2D6CcQ4RW6wHKo
+YfAkK8/g8PPqwYqzkKHp4EfoceCUcpluHljXPsCgYBMZK+/hyRyQXeyi2rGQjza
BWrIXnV8Rrz2gvV6DHt3Kg0Knkz74QjigZPhkyHyJsiXK2J+vOZY2yIm7C+qRES6
T9l+kYQ1CapetR2CYIRrVBKq22j1N5cwOR21a7aqX3G8ypjUG9I8QoUh8nAAcEZx
76F2eDonbbkRQoRrgppFsQKBgQCIrDGIstNdugF72YFTcecoATHaf3FYTLe7cMoQ
YDHDKkMqwO12CXXdb8qTQ5/MpenEc0o6SOR2HUzeiBV11Wrj9xBADymSt5gwFCXj
cKpz+C6hcaB42Tou+/X6+4cEZM8b9Z3k7zLirxQHxIP8/8Xq9JUXacMvm72sZSFG
6A9B0wKBgCCfWTnsHxrk7DTAMqrNm3iM1GA8fKWlCQ5n3H50zG/flUwECmAApHo1
BPz/tKa/DFv1UJwTVG1CyK2kGgpxqTSrstbB0Dyd8alN+3qt62ipje6FG6xlbFGz
SjK56xiPMOs4YGyrdSHYfniyxNvaLaSvuAfq/EITXpCdVJBSbKDQ
-----END RSA PRIVATE KEY-----"""

DEV_PUBLIC_KEY = """-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtPxP6pkLWjmG0GKxA+Ls
7XNEr6TecUQ6JeeqWNqguSQv6C10mq3Baz94UA/TQFqPlV6uLFrPlA/gC503CE+9
1vMWosvYUn844TWqGqsoCHvyLlhusJCgt9UWf0C42n5SLtqezV/Ej+LtbgOmU3/C
mokVmFrlpsMH0c07U2dCST998rG8UqQ8id1Zuq5mkTSa5xLGcH2/wMPJhpU2v+MJ
/7wmm/6DaU5T/qm4n2BjfOWZZ4Wzh3TOmkSTUPU0XXT8PzVEOF4l57srSgn9FjFq
5RtqIXPNH4KVhb6FL2w0TXjAdQ3YWAzvgB9fqZEe3EFsV/Yoic6qZfZRI89L7XMS
awIDAQAB
-----END PUBLIC KEY-----"""


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="APP_", extra="ignore")

    app_env: str = "development"
    database_url: str = "postgresql+asyncpg://scout:scout@auth-db:5432/auth_service"
    jwt_private_key: str | None = None
    jwt_public_key: str | None = None
    jwt_private_key_path: str | None = None
    jwt_public_key_path: str | None = None

    @property
    def private_key(self) -> str | None:
        if self.jwt_private_key:
            return self.jwt_private_key
        if self.jwt_private_key_path and os.path.exists(self.jwt_private_key_path):
            with open(self.jwt_private_key_path, "r", encoding="utf-8") as fh:
                return fh.read()
        return DEV_PRIVATE_KEY

    @property
    def public_key(self) -> str | None:
        if self.jwt_public_key:
            return self.jwt_public_key
        if self.jwt_public_key_path and os.path.exists(self.jwt_public_key_path):
            with open(self.jwt_public_key_path, "r", encoding="utf-8") as fh:
                return fh.read()
        return DEV_PUBLIC_KEY


@lru_cache
def get_settings() -> Settings:
    return Settings()
