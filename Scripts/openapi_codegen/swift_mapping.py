from __future__ import annotations

from typing import Any

from openapi_codegen.common import UnionCase, UnionMapping, pascal_case


RESPONSE_OVERRIDES = {
    "ClientRequestThreadNameSetRequest": "ThreadSetNameResponse",
    "ClientRequestAppListRequest": "AppsListResponse",
    "ClientRequestRemoteControlClientListRequest": "RemoteControlClientsListResponse",
    "ClientRequestRemoteControlClientRevokeRequest": "RemoteControlClientsRevokeResponse",
    "ClientRequestConfigMcpServerReloadRequest": "McpServerRefreshResponse",
    "ClientRequestMcpServerStatusListRequest": "ListMcpServerStatusResponse",
    "ClientRequestMcpServerResourceReadRequest": "McpResourceReadResponse",
    "ClientRequestAccountLoginStartRequest": "LoginAccountResponse",
    "ClientRequestAccountLoginCancelRequest": "CancelLoginAccountResponse",
    "ClientRequestAccountLogoutRequest": "LogoutAccountResponse",
    "ClientRequestAccountRateLimitsReadRequest": "GetAccountRateLimitsResponse",
    "ClientRequestAccountRateLimitResetCreditConsumeRequest": "ConsumeAccountRateLimitResetCreditResponse",
    "ClientRequestAccountUsageReadRequest": "GetAccountTokenUsageResponse",
    "ClientRequestAccountSendAddCreditsNudgeEmailRequest": "SendAddCreditsNudgeEmailResponse",
    "ClientRequestConfigValueWriteRequest": "ConfigWriteResponse",
    "ClientRequestConfigBatchWriteRequest": "ConfigWriteResponse",
    "ClientRequestAccountReadRequest": "GetAccountResponse",
    "ServerRequestItemCommandExecutionRequestApprovalRequest": "CommandExecutionRequestApprovalResponse",
    "ServerRequestItemFileChangeRequestApprovalRequest": "FileChangeRequestApprovalResponse",
    "ServerRequestItemToolRequestUserInputRequest": "ToolRequestUserInputResponse",
    "ServerRequestItemPermissionsRequestApprovalRequest": "PermissionsRequestApprovalResponse",
    "ServerRequestItemToolCallRequest": "DynamicToolCallResponse",
    "ServerRequestAccountChatgptAuthTokensRefreshRequest": "ChatgptAuthTokensRefreshResponse",
}


class SchemaIntrospector:
    def __init__(self, document: dict[str, Any]) -> None:
        self.schemas = document["components"]["schemas"]

    def union_mapping(
        self,
        schema_name: str,
        *,
        protocol_name: str,
        accessor_name: str,
        has_id: bool,
        has_response: bool,
    ) -> UnionMapping:
        schema = self.schemas[schema_name]
        cases = tuple(
            self.union_case(schema_name, ref, has_response=has_response)
            for ref in schema["oneOf"]
        )
        return UnionMapping(
            schema_name=schema_name,
            protocol_name=protocol_name,
            accessor_name=accessor_name,
            build_return_type=f"AppServerModels.{schema_name}",
            cases=cases,
            has_id=has_id,
        )

    def union_case(
        self,
        schema_name: str,
        ref_schema: dict[str, str],
        *,
        has_response: bool,
    ) -> UnionCase:
        component_name = ref_schema["$ref"].removeprefix("#/components/schemas/")
        component = self.schemas[component_name]
        properties = component.get("properties", {})
        method = self.singleton_string_value(properties["method"])
        required = set(component.get("required", []))
        return UnionCase(
            case_name=self.swift_case_name(method),
            alias_name=self.alias_name(schema_name, component_name),
            component_name=component_name,
            params_type=self.swift_type_for_schema(
                properties["params"],
                required="params" in required,
            ),
            response_type=(
                self.response_type_for_component(schema_name, component_name)
                if has_response
                else None
            ),
            properties=tuple(properties),
        )

    def response_type_for_component(self, schema_name: str, component_name: str) -> str:
        response_name = RESPONSE_OVERRIDES.get(component_name)
        if response_name is None:
            response_name = self.response_name_candidate(schema_name, component_name)
        if response_name not in self.schemas:
            raise ValueError(f"Missing response schema for {component_name}: {response_name}")
        return f"Components.Schemas.{response_name}"

    def response_name_candidate(self, schema_name: str, component_name: str) -> str:
        name = component_name
        if name.startswith(schema_name):
            name = name[len(schema_name):]
        if name.endswith("Request"):
            name = name[:-len("Request")]
        return f"{name}Response"

    def singleton_string_value(self, schema: dict[str, Any]) -> str:
        enum_values = schema.get("enum")
        if (
            isinstance(enum_values, list)
            and len(enum_values) == 1
            and isinstance(enum_values[0], str)
        ):
            return enum_values[0]
        const_value = schema.get("const")
        if isinstance(const_value, str):
            return const_value
        raise ValueError(f"Expected singleton string schema: {schema}")

    def swift_type_for_schema(self, schema: dict[str, Any], *, required: bool) -> str:
        optional = not required or schema.get("nullable") is True
        if "$ref" in schema:
            name = schema["$ref"].removeprefix("#/components/schemas/")
            return f"Components.Schemas.{name}{'?' if optional else ''}"
        return "OpenAPIRuntime.OpenAPIValueContainer?"

    def alias_name(self, schema_name: str, component_name: str) -> str:
        name = component_name
        if name.startswith(schema_name):
            name = name[len(schema_name):]
        for suffix in ("Request", "Notification"):
            if name.endswith(suffix):
                name = name[:-len(suffix)]
                break
        return name or component_name

    def swift_case_name(self, value: str) -> str:
        name = pascal_case(value)
        return name[:1].lower() + name[1:]


class SwiftMappingGenerator:
    def __init__(self, document: dict[str, Any]) -> None:
        introspector = SchemaIntrospector(document)
        self.mappings = (
            introspector.union_mapping(
                "ClientRequest",
                protocol_name="ClientRequestable",
                accessor_name="asClientRequest",
                has_id=True,
                has_response=True,
            ),
            introspector.union_mapping(
                "ServerRequest",
                protocol_name="ServerRequestable",
                accessor_name="asServerRequest",
                has_id=True,
                has_response=True,
            ),
            introspector.union_mapping(
                "ServerNotification",
                protocol_name="ServerNotificationPayload",
                accessor_name="asServerNotification",
                has_id=False,
                has_response=False,
            ),
        )

    def generate(self) -> str:
        lines: list[str] = [
            "// Generated by Scripts/generate-openapi.py; do not edit.",
            "",
            "import OpenAPIRuntime",
            "",
            "enum AppServerModels {",
            "    typealias ClientRequest = Components.Schemas.ClientRequest",
            "    typealias ServerRequest = Components.Schemas.ServerRequest",
            "    typealias ServerNotification = Components.Schemas.ServerNotification",
            "}",
            "",
        ]
        lines.extend(self.protocols())
        for mapping in self.mappings:
            lines.extend(self.union_extension(mapping))
            lines.extend(self.case_conformances(mapping))
        return "\n".join(lines).rstrip() + "\n"

    def protocols(self) -> list[str]:
        return [
            "protocol ClientRequestable {",
            "    associatedtype Params",
            "    associatedtype Response",
            "    static func build(id: Components.Schemas.RequestId, params: Params) -> AppServerModels.ClientRequest",
            "    var id: Components.Schemas.RequestId { get }",
            "    var params: Params { get }",
            "}",
            "",
            "protocol ServerRequestable {",
            "    associatedtype Params",
            "    associatedtype Response",
            "    static func build(id: Components.Schemas.RequestId, params: Params) -> AppServerModels.ServerRequest",
            "    var id: Components.Schemas.RequestId { get }",
            "    var params: Params { get }",
            "}",
            "",
            "protocol ServerNotificationPayload {",
            "    associatedtype Params",
            "    static func build(params: Params) -> AppServerModels.ServerNotification",
            "    var params: Params { get }",
            "}",
            "",
        ]

    def union_extension(self, mapping: UnionMapping) -> list[str]:
        lines = [f"extension AppServerModels.{mapping.schema_name} {{"]
        for case in mapping.cases:
            lines.append(
                f"    typealias {case.alias_name} = Components.Schemas.{case.component_name}"
            )
        response_cases = [case for case in mapping.cases if case.response_type is not None]
        if response_cases:
            lines.extend(["", "    enum Response {"])
            for case in response_cases:
                lines.append(f"        typealias {case.alias_name} = {case.response_type}")
            lines.append("    }")
        lines.extend([
            "",
            f"    var {mapping.accessor_name}: any {mapping.protocol_name} {{",
            "        switch self {",
        ])
        for case in mapping.cases:
            lines.append(f"        case let .{case.case_name}(value): value")
        lines.extend([
            "        }",
            "    }",
            "}",
            "",
        ])
        return lines

    def case_conformances(self, mapping: UnionMapping) -> list[str]:
        lines: list[str] = []
        for case in mapping.cases:
            lines.extend(self.case_conformance(mapping, case))
        return lines

    def case_conformance(self, mapping: UnionMapping, case: UnionCase) -> list[str]:
        component_type = f"Components.Schemas.{case.component_name}"
        lines = [
            f"extension {component_type}: {mapping.protocol_name} {{",
            f"    typealias Params = {case.params_type}",
        ]
        if case.response_type is not None:
            lines.append(
                f"    typealias Response = AppServerModels.{mapping.schema_name}.Response.{case.alias_name}"
            )
        if mapping.has_id:
            lines.extend([
                f"    static func build(id: Components.Schemas.RequestId, params: Params) -> {mapping.build_return_type} {{",
                f"        .{case.case_name}(.init({self.initializer_arguments(case, include_id=True)}))",
                "    }",
            ])
        else:
            lines.extend([
                f"    static func build(params: Params) -> {mapping.build_return_type} {{",
                f"        .{case.case_name}(.init({self.initializer_arguments(case, include_id=False)}))",
                "    }",
            ])
        lines.extend(["}", ""])
        return lines

    def initializer_arguments(self, case: UnionCase, *, include_id: bool) -> str:
        arguments: list[str] = []
        for property_name in case.properties:
            if property_name == "id" and include_id:
                arguments.append("id: id")
            elif property_name == "method":
                arguments.append("method: .allCases.first!")
            elif property_name == "params":
                arguments.append("params: params")
        return ", ".join(arguments)
