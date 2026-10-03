#!/usr/bin/env bash

# ==============================================================================
# MikroTik Backup Script
# ==============================================================================
#
# Single-file RouterOS backup application with command-line, interactive,
# device-source, storage, transport, backup, comparison and archive subsystems.
#

set -o pipefail
umask 077

# Canonical product and presentation metadata. ProgramVersion is the only
# production source of the release version.
readonly ProgramName='MikroTik Backup Script'
readonly ProgramVersion='2.3.1'
readonly ProgramYear=2026
readonly ProgramAuthor='Pavel Korsakov'
readonly ProgramWebsite='https://korsakov.dev'
readonly UiWidth=46
readonly InstructionWidth=80
declare -gra MasterFields=(
    DeviceName Address User Password SshPort
    backup_type UseIncremental export_format show_sensitive encrypt clear_dns_cache clear_console_history
    BackupRoot UseNetFolder UseIdentityName
)
declare -gra MasterActions=(execute save copy return)

# Central presentation palette shared by every interactive selector and screen.
declare -grA TerminalPalette=(
    [ProductHeader]=$'\033[38;5;255m'
    [MainTitle]=$'\033[38;5;117m'
    [MainDescription]=$'\033[38;5;117m'
    [HelpTitle]=$'\033[38;5;117m'
    [HelpDescription]=$'\033[38;5;117m'
    [InstructionTitle]=$'\033[38;5;117m'
    [MasterTitle]=$'\033[38;5;159m'
    [MasterDescription]=$'\033[38;5;159m'
    [EditorTitle]=$'\033[1;32m'
    [EditorSelected]=$'\033[1;97m'
    [EditorLabel]=$'\033[38;5;250m'
    [EditorDisabled]=$'\033[2m'
    [EditorValueYes]=$'\033[38;5;151m'
    [EditorValueNo]=$'\033[38;5;217m'
    [EditorValuePath]=$'\033[38;5;183m'
    [EditorValueOrdinary]=$'\033[38;5;215m'
    [EditorDescription]=$'\033[38;5;229m'
    [EditorStructural]=$'\033[38;5;250m'
    [DocumentHeading]=$'\033[1;97m'
    [DocumentText]=$'\033[38;5;250m'
    [DocumentCode]=$'\033[38;5;215m'
    [LoggingSuccess]=$'\033[1;32m'
    [LoggingError]=$'\033[1;31m'
    [Reset]=$'\033[0m'
)

# ==============================================================================
# Product metadata and shared plain header
# ==============================================================================

# Назначение: Собирает единый текстовый заголовок продукта заданной ширины для конфигурационных файлов и экранов.
# shellcheck disable=SC2034  # HeaderOut is a nameref output.
build_product_header()
{
    local Width="$1"
    local -n HeaderOut="$2"
    local Rule=''

    (( Width >= 4 )) || return 80
    printf -v Rule '%*s' "$((Width - 2))" ''
    Rule="# ${Rule// /=}"
    printf -v HeaderOut '%s\n# %s %s (%s)\n# By %s (%s)\n%s' \
        "$Rule" "$ProgramName" "$ProgramVersion" "$ProgramYear" \
        "$ProgramAuthor" "$ProgramWebsite" "$Rule"
    return 0
}

# ==============================================================================
# Runtime bootstrap and global state
# ==============================================================================

# Назначение: Отклоняет интерпретаторы старше допустимого минимума Bash 4.4 до использования несовместимых возможностей.
check_bash_version()
{
    local Major="${1:-${BASH_VERSINFO[0]:-0}}"
    local Minor="${2:-${BASH_VERSINFO[1]:-0}}"

    if (( Major < 4 || (Major == 4 && Minor < 4) )); then
        printf '%s\n' 'MikroTik Backup Script requires Bash 4.4 or newer.' >&2
        return 80
    fi
    return 0
}

# Назначение: Пересоздаёт все глобальные таблицы и начальные флаги одного запуска, не сохраняя состояние предыдущего выполнения.
bootstrap_runtime()
{
    local DeviceId
    local ProgramSource="${BASH_SOURCE[0]}"
    local ProgramSourceDirectory='.'
    local ProgramDirectory=''

    if [[ "$ProgramSource" == */* ]]; then
        ProgramSourceDirectory="${ProgramSource%/*}"
    fi
    ProgramDirectory="$(cd -P -- "$ProgramSourceDirectory" && pwd)" || return 80

    if declare -p DeviceIds >/dev/null 2>&1; then
        for DeviceId in "${DeviceIds[@]}"; do
            if [[ "$DeviceId" =~ ^DeviceContext_[0-9]+$ ]]; then
                unset -v "$DeviceId"
            fi
        done
    fi

    declare -gA RuntimeState=()
    declare -gA CliState=()
    declare -gA CliActions=()
    declare -gA DefaultValues=()
    declare -gA EffectiveConfig=()
    declare -gA ExecutionIntent=()
    declare -gA ExecutionState=()
    declare -gA DependencyProfile=()
    declare -gA MessagesEn=()
    declare -gA MessagesRu=()
    declare -gA PresentationMessages=()
    declare -gA ParsedOptionConfig=()
    declare -gA ParsedOptionSeen=()
    declare -gA SourceStats=()
    declare -gA SourceSeenKeys=()
    declare -gA DeclaredNameClaims=()
    declare -gA DeviceNameClaims=()
    declare -gA OxidizedSchema=()
    declare -gA StorageContext=()
    declare -gA LockContext=()
    declare -gA MikrotikDriver=()
    declare -gA TransportDiagnostic=()
    declare -gA RunState=()
    declare -gA ArtifactContext=()
    declare -gA LoggingState=()
    # Keys are script or device:<context>; presence suppresses repeat sink errors.
    declare -gA LogSinkFailureReported=()
    declare -ga CleanupRegistry=()
    declare -ga RuntimeWarnings=()
    declare -ga DeviceIds=()
    declare -ga OxidizedModelRuleTypes=()
    declare -ga OxidizedModelRuleKeys=()
    declare -ga OxidizedModelRuleValues=()
    # Parallel indices preserve early-event chronology. Domain is script|device;
    # role/detail retain main/subevent and short/full/error filtering semantics.
    declare -ga EarlyLogEventDomains=()
    declare -ga EarlyLogEventRoles=()
    declare -ga EarlyLogEventDetails=()
    declare -ga EarlyLogEventDeviceIds=()
    declare -ga EarlyLogEventMessageKeys=()
    declare -ga EarlyLogEventResultCodes=()
    # Kind, subevent number and requested block boundary are the narrow additive
    # metadata needed to render buffered semantic records without text parsing.
    declare -ga EarlyLogEventKinds=()
    declare -ga EarlyLogEventNumbers=()
    declare -ga EarlyLogEventBoundaries=()
    declare -ga EarlyLogEventPayloadTypes=()
    declare -ga EarlyLogEventPayloadOnes=()
    declare -ga EarlyLogEventPayloadTwos=()
    declare -ga EarlyLogEventPayloadThrees=()
    declare -ga EarlyLogEventPayloadFours=()
    declare -ga TerminalLogErrorMessages=()
    declare -ga TerminalLogErrorCodes=()
    declare -ga TerminalLogBatchRows=()
    declare -ga TerminalLogDeviceMainRows=()
    declare -ga TerminalLogDeviceErrorMessages=()
    declare -ga TerminalLogDeviceErrorCodes=()

    RuntimeState[CleanupDone]=false
    RuntimeState[CleanupEntryCounter]=0
    RuntimeState[DeviceContextCounter]=0
    RuntimeState[SignalDeferral]=false
    RuntimeState[PendingSignal]=''
    RuntimeState[ActiveTransportOwned]=false
    RuntimeState[ActiveTransportWaitable]=false
    RuntimeState[ActiveTransportPid]=''
    RuntimeState[ActiveTransportPgid]=''
    RuntimeState[PasswordChannelFd]=''
    RuntimeState[NamingLocaleReady]=false
    RuntimeState[WarningCount]=0
    RuntimeState[WorkingDirectory]="$PWD"
    RuntimeState[ProgramDirectory]="$ProgramDirectory"
    RuntimeState[OptionConfigPath]="$ProgramDirectory/option.cfg"
    RuntimeState[DeviceListPath]="$ProgramDirectory/devicelist.cfg"
    RuntimeState[BackupTrace]=''
    RuntimeState[IncrementalTrace]=''
    RuntimeState[ArchiveTrace]=''
    RuntimeState[MonthlyArchiveEnabled]=false
    RuntimeState[MonthlyArchiveDue]=false
    RuntimeState[MonthlyArchiveRunDate]=''
    RuntimeState[MonthlyArchiveDay]=''
    RuntimeState[MonthlyArchiveLabel]=''
    RuntimeState[ProgramVersion]="$ProgramVersion"
    RuntimeState[StartupConfigLoaded]=false
    RuntimeState[StartupConfigExists]=false
    RuntimeState[StartupConfigUsable]=false
    RuntimeState[PresentationLanguage]=en
    RuntimeState[TerminalStateActive]=false
    RuntimeState[TerminalTransitionPending]=false
    RuntimeState[TerminalSavedState]=''
    RuntimeState[TerminalFrameValidation]=false
    RuntimeState[WizardExecuted]=false
    LoggingState[ConfigurationResolved]=false
    LoggingState[FileRoutingReady]=false
    LoggingState[UseFallback]=false
    LoggingState[MainRecordWritten]=false
    LoggingState[MainSeparatorRequested]=false
    LoggingState[EarlyFlushAttempted]=false
    LoggingState[TerminalContext]=''
    LoggingState[TerminalLevel]=''
    LoggingState[TerminalMainActive]=false
    LoggingState[TerminalMainVisible]=false
    LoggingState[TerminalMainMessage]=''
    LoggingState[TerminalCurrentSubevent]=''
    LoggingState[TerminalBatchActive]=false
    LoggingState[TerminalBatchParentVisible]=false
    LoggingState[TerminalBatchParentMessage]=''
    LoggingState[TerminalBatchChildActive]=false
    LoggingState[TerminalBatchChildVisible]=false
    LoggingState[TerminalBatchChildMessage]=''
    LoggingState[TerminalDeviceMainActive]=false
    LoggingState[TerminalDeviceMainVisible]=false
    LoggingState[TerminalDeviceMainMessage]=''
    LoggingState[TerminalRows]=0
    LoggingState[TerminalSpinnerActive]=false
    LoggingState[TerminalSpinnerPid]=''
    RunState[StopRun]=false
    promote_run_result 0
}

# ==============================================================================
# Run result, warnings and final reporting
# ==============================================================================

# Назначение: Повышает итоговый код запуска по политике «ошибка сильнее предупреждения», не затирая уже более серьёзный результат.
promote_run_result()
{
    local Candidate="$1"
    local Current=0

    if [[ -z "${RuntimeState[RunResult]+x}" ]]; then
        RuntimeState[RunResult]=0
    fi
    Current="${RuntimeState[RunResult]}"
    if (( Candidate != 0 && (Current == 0 || Current == 1 && Candidate != 1) )); then
        RuntimeState[RunResult]="$Candidate"
    fi
    return 0
}

# Назначение: Регистрирует ключ предупреждения, увеличивает счётчик и переводит успешный итог запуска в предупреждение.
record_warning()
{
    local WarningKey="${1:-warning_generic}"

    RuntimeWarnings+=("$WarningKey")
    RuntimeState[WarningCount]="$((${RuntimeState[WarningCount]:-0} + 1))"
    promote_run_result 1
    return 0
}

# Назначение: Выбирает путь main.log из effective-конфигурации, канонического корня либо безопасного fallback и возвращает его через nameref.
# shellcheck disable=SC2034  # PathOut is a nameref output.
resolve_main_journal_path()
{
    local -n PathOut="$1"
    local Directory=''
    local BackupRoot=''

    PathOut=''
    if [[ "${LoggingState[UseFallback]:-false}" == true ]]; then
        Directory="${RuntimeState[ProgramDirectory]}/${DefaultValues[BackupRoot]:-backups}"
    else
        [[ "${LoggingState[ConfigurationResolved]:-false}" == true ]] || return 80
        if [[ -n "${EffectiveConfig[MainLogPath]:-}" ]]; then
            Directory="${EffectiveConfig[MainLogPath]}"
        elif [[ -n "${StorageContext[CanonicalRoot]:-}" ]]; then
            Directory="${StorageContext[CanonicalRoot]}"
        else
            BackupRoot="${EffectiveConfig[BackupRoot]:-}"
            [[ -n "$BackupRoot" ]] || return 80
            if [[ "$BackupRoot" == /* ]]; then
                Directory="$BackupRoot"
            else
                Directory="${RuntimeState[ProgramDirectory]}/$BackupRoot"
            fi
        fi
    fi
    [[ -n "$Directory" ]] || return 80
    if [[ "$Directory" == / ]]; then
        PathOut=/main.log
    else
        PathOut="${Directory%/}/main.log"
    fi
    return 0
}

# Назначение: Строит путь журнала устройства по подготовленному контексту и различает batch- и single-именование.
# shellcheck disable=SC2034  # PathOut is a nameref output.
resolve_device_journal_path()
{
    local DeviceId="$1"
    local -n PathOut="$2"
    local Declaration=''
    local DeviceName=''
    local DeviceDirectory=''
    local BuiltPath=''

    PathOut=''
    [[ "$DeviceId" =~ ^DeviceContext_[1-9][0-9]*$ ]] || return 80
    Declaration="$(declare -p "$DeviceId" 2>/dev/null)" || return 80
    [[ "$Declaration" == "declare -A $DeviceId="* ]] || return 80
    local -n JournalDeviceContext="$DeviceId"
    DeviceName="${JournalDeviceContext[DeviceName]:-}"
    DeviceDirectory="${JournalDeviceContext[PreparedDirectory]:-}"
    validate_device_name "$DeviceName" >/dev/null 2>&1 || return 80
    [[ -n "$DeviceDirectory" && "$DeviceDirectory" != */ ]] || return 80

    case "${ExecutionState[RunMode]:-}" in
        batch)
            PathOut="$DeviceDirectory/$DeviceName.log"
            ;;
        single)
            build_local_artifact_path "$DeviceName" \
                "${JournalDeviceContext[BackupTimestamp]:-}" log \
                "$DeviceDirectory" BuiltPath || return $?
            PathOut="$BuiltPath"
            ;;
        *) return 80 ;;
    esac
    return 0
}

# Назначение: Проверяет согласованность домена, роли, детализации, кода и семантического вида события до записи в журнал.
validate_journal_event()
{
    local Domain="$1"
    local Role="$2"
    local Detail="$3"
    local DeviceId="$4"
    local MessageKey="$5"
    local ResultCode="$6"
    local Kind="$7"
    local Number="$8"
    local Boundary="$9"
    local Declaration=''

    case "$Domain" in
        script) [[ -z "$DeviceId" ]] || return 80 ;;
        device)
            [[ "$DeviceId" =~ ^DeviceContext_[1-9][0-9]*$ ]] || return 80
            Declaration="$(declare -p "$DeviceId" 2>/dev/null)" || return 80
            [[ "$Declaration" == "declare -A $DeviceId="* ]] || return 80
            ;;
        *) return 80 ;;
    esac
    case "$Role" in
        grouping|context|main|subevent) : ;;
        *) return 80 ;;
    esac
    case "$Detail" in
        short|full|error) : ;;
        *) return 80 ;;
    esac
    case "$Kind" in
        ordinary|start|outcome|error) : ;;
        *) return 80 ;;
    esac
    case "$Boundary" in
        none|block) : ;;
        *) return 80 ;;
    esac
    [[ "$MessageKey" =~ ^[a-z][a-z0-9_]*$ &&
       ( -n "${PresentationMessages[$MessageKey]+x}" ||
         -n "${MessagesEn[$MessageKey]+x}" ) ]] || return 80
    [[ -z "$ResultCode" || "$ResultCode" =~ ^(0|[1-9][0-9]*)$ ]] || return 80

    if [[ "$Role" == subevent ]]; then
        [[ "$Number" =~ ^[1-9][0-9]*$ &&
           ( "$Kind" == ordinary || "$Kind" == error ) ]] || return 80
    else
        [[ -z "$Number" ]] || return 80
    fi
    case "$Kind" in
        ordinary|start) [[ -z "$ResultCode" ]] || return 80 ;;
        outcome) [[ -n "$ResultCode" && "$Role" == main ]] || return 80 ;;
        error) [[ "$ResultCode" != 0 ]] || return 80 ;;
    esac
    case "$Role" in
        grouping) [[ "$Kind" == ordinary ]] || return 80 ;;
        context) [[ "$Kind" == ordinary || "$Kind" == error ]] || return 80 ;;
        main) [[ "$Kind" != ordinary ]] || return 80 ;;
    esac
    return 0
}

# Назначение: Проверяет типизированные поля payload, чтобы форматтер получал только допустимые числа, имена устройств и комбинации значений.
validate_log_payload()
{
    local PayloadType="${1:-none}"
    local One="${2:-}"
    local Two="${3:-}"
    local Three="${4:-}"
    local Four="${5:-}"
    local CanonicalDevice=''

    case "$PayloadType" in
        none)
            [[ -z "$One$Two$Three$Four" ]] || return 80
            ;;
        source_stats)
            [[ "$One" =~ ^(0|[1-9][0-9]*)$ &&
               "$Two" =~ ^(0|[1-9][0-9]*)$ &&
               "$Three" =~ ^(0|[1-9][0-9]*)$ &&
               "$Four" =~ ^(0|[1-9][0-9]*)$ ]] || return 80
            ;;
        batch_device)
            [[ "$One" =~ ^[1-9][0-9]*$ && "$Two" =~ ^[1-9][0-9]*$ ]] || return 80
            (( One <= Two )) || return 80
            [[ -z "$Four" ]] || return 80
            if [[ -n "$Three" ]]; then
                normalize_device_name "$Three" CanonicalDevice >/dev/null 2>&1 || return 80
                [[ "$CanonicalDevice" == "$Three" ]] || return 80
                validate_device_name "$Three" >/dev/null 2>&1 || return 80
                [[ "$Three" != *[$'\001'-$'\037'$'\177']* ]] || return 80
            fi
            ;;
        device_name)
            [[ -n "$One" && -z "$Two$Three$Four" ]] || return 80
            normalize_device_name "$One" CanonicalDevice >/dev/null 2>&1 || return 80
            [[ "$CanonicalDevice" == "$One" ]] || return 80
            validate_device_name "$One" >/dev/null 2>&1 || return 80
            [[ "$One" != *[$'\001'-$'\037'$'\177']* ]] || return 80
            ;;
        *) return 80 ;;
    esac
    return 0
}

# Назначение: Подставляет строго ожидаемые аргументы в локализованный шаблон сообщения и отвергает несовпадение его схемы.
# shellcheck disable=SC2034  # MessageOut is a nameref output.
expand_log_message_template()
{
    local Template="$1"
    local PayloadType="$2"
    local One="$3"
    local Two="$4"
    local Three="$5"
    local Four="$6"
    local -n MessageOut="$7"
    local Token=''
    local Value=''
    local ValueCount=0
    local Occurrences=0
    local Expanded="$Template"
    local -a Tokens=()
    local -a Values=()

    MessageOut=''
    validate_log_payload "$PayloadType" "$One" "$Two" "$Three" "$Four" || return $?
    [[ -n "$Template" && "$Template" != *[$'\001'-$'\037'$'\177']* ]] || return 80
    case "$PayloadType" in
        none) : ;;
        source_stats)
            Tokens=(read accepted filtered skipped)
            Values=("$One" "$Two" "$Three" "$Four")
            ;;
        batch_device)
            Tokens=(index total)
            Values=("$One" "$Two")
            if [[ -n "$Three" ]]; then
                Tokens+=(device)
                Values+=("$Three")
            fi
            ;;
        device_name)
            Tokens=(device)
            Values=("$One")
            ;;
    esac
    for ((Occurrences=0; Occurrences<${#Tokens[@]}; Occurrences++)); do
        Token="{${Tokens[Occurrences]}}"
        Value="${Values[Occurrences]}"
        count_literal_occurrences "$Template" "$Token" ValueCount || return 80
        (( ValueCount == 1 )) || return 80
        Expanded="${Expanded//"$Token"/$Value}"
    done
    [[ "$Expanded" != *'{'* && "$Expanded" != *'}'* ]] || return 80
    MessageOut="$Expanded"
    return 0
}

# Назначение: Выбирает локализованный шаблон и формирует готовый текст события из проверенного payload.
# shellcheck disable=SC2034  # MessageOut is a nameref output.
render_log_message()
{
    local MessageKey="$1"
    local PayloadType="${2:-none}"
    local One="${3:-}"
    local Two="${4:-}"
    local Three="${5:-}"
    local Four="${6:-}"
    local -n MessageOut="$7"
    local Template=''
    local Rendered=''

    MessageOut=''
    validate_log_payload "$PayloadType" "$One" "$Two" "$Three" "$Four" || return $?
    localized_message "$MessageKey" Template || return $?
    if expand_log_message_template "$Template" "$PayloadType" \
        "$One" "$Two" "$Three" "$Four" Rendered; then
        MessageOut="$Rendered"
        return 0
    fi
    Template="${MessagesEn[$MessageKey]:-}"
    expand_log_message_template "$Template" "$PayloadType" \
        "$One" "$Two" "$Three" "$Four" Rendered || return $?
    MessageOut="$Rendered"
    return 0
}

# Назначение: Решает, должен ли уровень детализации конкретного события попадать в выбранный журнал.
journal_event_is_eligible()
{
    local Detail="$1"
    local Kind="$2"
    local ResultCode="$3"
    local Level=''

    if [[ "${LoggingState[UseFallback]:-false}" == true ]]; then
        Level="${DefaultValues[LogLevel]:-2}"
    else
        Level="${EffectiveConfig[LogLevel]:-}"
    fi
    [[ "$Level" =~ ^[0-3]$ ]] || return 80
    if [[ "$Detail" == error || "$Kind" == error ||
          ( -n "$ResultCode" && "$ResultCode" != 0 ) ]]; then
        return 0
    fi
    case "$Level" in
        0) return 1 ;;
        1) [[ "$Detail" == short ]] ;;
        2|3) return 0 ;;
    esac
}

# Назначение: Преобразует семантическое событие в одну каноническую строку журнала с датой, ролью и результатом.
# shellcheck disable=SC2034  # RecordOut is a nameref output.
format_journal_record()
{
    local Domain="$1"
    local Role="$2"
    local Kind="$3"
    local Number="$4"
    local MessageKey="$5"
    local ResultCode="$6"
    local -n RecordOut="$7"
    local PayloadType="${8:-none}"
    local PayloadOne="${9:-}"
    local PayloadTwo="${10:-}"
    local PayloadThree="${11:-}"
    local PayloadFour="${12:-}"
    local Timestamp=''
    local Message=''
    local RenderedRecord=''

    RecordOut=''
    Timestamp="$(LC_ALL=C date '+%Y-%m-%d %H:%M:%S' 2>/dev/null)" || return 80
    [[ "$Timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]] || return 80
    render_log_message "$MessageKey" "$PayloadType" \
        "$PayloadOne" "$PayloadTwo" "$PayloadThree" "$PayloadFour" Message || return $?

    RenderedRecord="[$Timestamp]"
    if [[ "$Domain" == script ]]; then
        [[ "$BASHPID" =~ ^[1-9][0-9]*$ ]] || return 80
        RenderedRecord+=" [PID:$BASHPID]"
    fi
    if [[ "$Role" == subevent ]]; then
        RenderedRecord+=" [$Number]"
    fi
    if [[ "$Kind" == outcome ]]; then
        if [[ "$ResultCode" == 0 ]]; then
            RenderedRecord+=' [OK]'
        else
            RenderedRecord+=' [ER]'
            RenderedRecord+=" [$ResultCode]"
        fi
    elif [[ "$Kind" == error ]]; then
        RenderedRecord+=' [ER]'
        [[ -z "$ResultCode" ]] || RenderedRecord+=" [$ResultCode]"
    fi
    RenderedRecord+=" $Message"
    RecordOut="$RenderedRecord"
    return 0
}

# Назначение: Дописывает строку в журнал с закрытым umask и возвращает ошибку файловой записи вызывающему коду.
append_journal_line()
{
    local Path="$1"
    local Line="$2"

    [[ -n "$Path" ]] || return 80
    [[ -z "$Line" || "$Line" != *[$'\001'-$'\037'$'\177']* ]] || return 80
    printf '%s\n' "$Line" 2>/dev/null >> "$Path"
}

# Назначение: Запоминает требование отделить следующий главный результат пустой строкой, не записывая её преждевременно.
request_journal_separator()
{
    local Domain="$1"
    local DeviceId="${2:-}"
    local Declaration=''

    case "$Domain" in
        script)
            [[ -z "$DeviceId" ]] || return 80
            LoggingState[MainSeparatorRequested]=true
            ;;
        device)
            [[ "$DeviceId" =~ ^DeviceContext_[1-9][0-9]*$ ]] || return 80
            Declaration="$(declare -p "$DeviceId" 2>/dev/null)" || return 80
            [[ "$Declaration" == "declare -A $DeviceId="* ]] || return 80
            LoggingState["DeviceSeparatorRequested:$DeviceId"]=true
            ;;
        *) return 80 ;;
    esac
    return 0
}

# Назначение: Подготавливает состояние журналирования очередного устройства и границу между последовательными проходами.
begin_device_journal_pass()
{
    local DeviceId="$1"
    local Declaration=''

    [[ "$DeviceId" =~ ^DeviceContext_[1-9][0-9]*$ ]] || return 80
    Declaration="$(declare -p "$DeviceId" 2>/dev/null)" || return 80
    [[ "$Declaration" == "declare -A $DeviceId="* ]] || return 80
    unset 'LogSinkFailureReported[device:'"$DeviceId"']'
    LoggingState["DeviceRecordWritten:$DeviceId"]=false
    case "${ExecutionState[RunMode]:-}" in
        batch) LoggingState["DeviceSeparatorRequested:$DeviceId"]=true ;;
        single) LoggingState["DeviceSeparatorRequested:$DeviceId"]=false ;;
        *) return 80 ;;
    esac
    return 0
}

# Назначение: Один раз сообщает отказ конкретного файлового sink и отражает его в результате запуска без рекурсии журналирования.
report_journal_sink_failure()
{
    local Domain="$1"
    local DeviceId="${2:-}"
    local FailureKey=''
    local WarningKey=''

    case "$Domain" in
        script)
            [[ -z "$DeviceId" ]] || return 80
            FailureKey=script
            WarningKey=journal_script_sink_failure
            ;;
        device)
            [[ "$DeviceId" =~ ^DeviceContext_[1-9][0-9]*$ ]] || return 80
            FailureKey="device:$DeviceId"
            WarningKey=journal_device_sink_failure
            ;;
        *) return 80 ;;
    esac
    if [[ "${LogSinkFailureReported[$FailureKey]:-false}" == true ]]; then
        return 0
    fi
    LogSinkFailureReported["$FailureKey"]=true
    record_warning "$WarningKey"

    if [[ "$Domain" == device &&
          "${LoggingState[FileRoutingReady]:-false}" == true ]]; then
        write_journal_event script context error '' \
            journal_device_sink_failure 1 error '' none || :
    fi
    if [[ "${LoggingState[ConfigurationResolved]:-false}" == true ||
          "${LoggingState[UseFallback]:-false}" == true ]]; then
        render_terminal_log_event "${LoggingState[TerminalContext]:-shell}" \
            script context error '' "$WarningKey" 1 error '' none \
            none '' '' '' '' primary || :
    fi
    return 0
}

# Назначение: Маршрутизирует проверенное событие в main/device журнал, соблюдая детализацию, разделители и обработку отказа sink.
write_journal_event()
{
    local Domain="$1"
    local Role="$2"
    local Detail="$3"
    local DeviceId="$4"
    local MessageKey="$5"
    local ResultCode="$6"
    local Kind="$7"
    local Number="$8"
    local Boundary="$9"
    local PayloadType="${10:-none}"
    local PayloadOne="${11:-}"
    local PayloadTwo="${12:-}"
    local PayloadThree="${13:-}"
    local PayloadFour="${14:-}"
    local Path=''
    local Record=''
    local RecordStateKey=''
    local SeparatorStateKey=''
    local NeedSeparator=false
    local EligibilityStatus=0

    validate_journal_event "$Domain" "$Role" "$Detail" "$DeviceId" \
        "$MessageKey" "$ResultCode" "$Kind" "$Number" "$Boundary" || return $?
    validate_log_payload "$PayloadType" "$PayloadOne" "$PayloadTwo" \
        "$PayloadThree" "$PayloadFour" || return $?
    journal_event_is_eligible "$Detail" "$Kind" "$ResultCode" || EligibilityStatus=$?
    if (( EligibilityStatus == 1 )); then
        return 0
    elif (( EligibilityStatus != 0 )); then
        return "$EligibilityStatus"
    fi

    if [[ "$Domain" == script ]]; then
        resolve_main_journal_path Path || return $?
        RecordStateKey=MainRecordWritten
        SeparatorStateKey=MainSeparatorRequested
        if [[ "${LoggingState[$RecordStateKey]:-false}" != true && -s "$Path" ]]; then
            NeedSeparator=true
        fi
    else
        resolve_device_journal_path "$DeviceId" Path || return $?
        RecordStateKey="DeviceRecordWritten:$DeviceId"
        SeparatorStateKey="DeviceSeparatorRequested:$DeviceId"
    fi
    if [[ "$Boundary" == block ||
          "${LoggingState[$SeparatorStateKey]:-false}" == true ]]; then
        [[ -s "$Path" ]] && NeedSeparator=true
    fi

    if [[ "$NeedSeparator" == true ]]; then
        if ! append_journal_line "$Path" ''; then
            report_journal_sink_failure "$Domain" "$DeviceId" || :
        fi
    fi
    format_journal_record "$Domain" "$Role" "$Kind" "$Number" \
        "$MessageKey" "$ResultCode" Record "$PayloadType" "$PayloadOne" \
        "$PayloadTwo" "$PayloadThree" "$PayloadFour" || return $?
    if ! append_journal_line "$Path" "$Record"; then
        report_journal_sink_failure "$Domain" "$DeviceId" || :
        return 0
    fi
    LoggingState["$RecordStateKey"]=true
    LoggingState["$SeparatorStateKey"]=false
    return 0
}

# Назначение: Сохраняет раннее событие и его типизированный payload в параллельных массивах до готовности файловой маршрутизации.
buffer_journal_event()
{
    local PayloadType="${10:-none}"
    local PayloadOne="${11:-}"
    local PayloadTwo="${12:-}"
    local PayloadThree="${13:-}"
    local PayloadFour="${14:-}"

    validate_journal_event "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" || return $?
    validate_log_payload "$PayloadType" "$PayloadOne" "$PayloadTwo" \
        "$PayloadThree" "$PayloadFour" || return $?
    EarlyLogEventDomains+=("$1")
    EarlyLogEventRoles+=("$2")
    EarlyLogEventDetails+=("$3")
    EarlyLogEventDeviceIds+=("$4")
    EarlyLogEventMessageKeys+=("$5")
    EarlyLogEventResultCodes+=("$6")
    EarlyLogEventKinds+=("$7")
    EarlyLogEventNumbers+=("$8")
    EarlyLogEventBoundaries+=("$9")
    EarlyLogEventPayloadTypes+=("$PayloadType")
    EarlyLogEventPayloadOnes+=("$PayloadOne")
    EarlyLogEventPayloadTwos+=("$PayloadTwo")
    EarlyLogEventPayloadThrees+=("$PayloadThree")
    EarlyLogEventPayloadFours+=("$PayloadFour")
    return 0
}

# Назначение: Проверяет семантическое событие и либо буферизует его, либо немедленно пишет в доступные журналы.
log_semantic_event()
{
    if [[ "${LoggingState[FileRoutingReady]:-false}" != true ]]; then
        buffer_journal_event "$@"
        return $?
    fi
    write_journal_event "$@"
}

# Назначение: Одновременно передаёт событие в постоянный журнал и в активное терминальное представление.
emit_runtime_log_event()
{
    local Context="$1"
    local Domain="$2"
    local Role="$3"
    local Detail="$4"
    local DeviceId="$5"
    local MessageKey="$6"
    local ResultCode="$7"
    local Kind="$8"
    local Number="$9"
    local Boundary="${10}"
    local PayloadType="${11:-none}"
    local PayloadOne="${12:-}"
    local PayloadTwo="${13:-}"
    local PayloadThree="${14:-}"
    local PayloadFour="${15:-}"
    local TerminalLayer="${16:-primary}"
    local Message=''

    [[ "$Context" == returning || "$Context" == shell ]] || return 80
    [[ "$TerminalLayer" == primary || "$TerminalLayer" == batch_parent ||
       "$TerminalLayer" == batch_child || "$TerminalLayer" == device_group ||
       "$TerminalLayer" == device_main ]] || return 80
    validate_journal_event "$Domain" "$Role" "$Detail" "$DeviceId" \
        "$MessageKey" "$ResultCode" "$Kind" "$Number" "$Boundary" || return $?
    render_log_message "$MessageKey" "$PayloadType" "$PayloadOne" \
        "$PayloadTwo" "$PayloadThree" "$PayloadFour" Message || return $?
    [[ -n "$Message" ]] || return 80

    log_semantic_event "$Domain" "$Role" "$Detail" "$DeviceId" \
        "$MessageKey" "$ResultCode" "$Kind" "$Number" "$Boundary" \
        "$PayloadType" "$PayloadOne" "$PayloadTwo" "$PayloadThree" \
        "$PayloadFour" || :
    if [[ "${LoggingState[ConfigurationResolved]:-false}" == true ||
          "${LoggingState[UseFallback]:-false}" == true ]]; then
        render_terminal_log_event "$Context" "$Domain" "$Role" "$Detail" \
            "$DeviceId" "$MessageKey" "$ResultCode" "$Kind" "$Number" \
            "$Boundary" "$PayloadType" "$PayloadOne" "$PayloadTwo" \
            "$PayloadThree" "$PayloadFour" "$TerminalLayer" || :
    fi
    return 0
}

# Назначение: Ограничивает выгрузку ранних событий одной попыткой: отмечает попытку до flush и использует effective либо fallback-маршрут независимо от успеха записи.
flush_runtime_log_events()
{
    local Mode="$1"

    case "$Mode" in
        effective|fallback) : ;;
        *) return 80 ;;
    esac
    if [[ "${LoggingState[EarlyFlushAttempted]:-false}" == true ]]; then
        return 0
    fi
    LoggingState[EarlyFlushAttempted]=true
    flush_early_log_events "$Mode"
}

# Назначение: Последовательно воспроизводит накопленные ранние события и очищает буфер только после обработки всей очереди.
flush_early_log_events()
{
    local Mode="$1"
    local Count="${#EarlyLogEventDomains[@]}"
    local Index=0
    local ArrayName=''
    # shellcheck disable=SC2034  # Populated through resolve_main_journal_path's nameref output.
    local MainJournalPath=''
    local -a ParallelArrays=(
        EarlyLogEventRoles EarlyLogEventDetails EarlyLogEventDeviceIds
        EarlyLogEventMessageKeys EarlyLogEventResultCodes EarlyLogEventKinds
        EarlyLogEventNumbers EarlyLogEventBoundaries EarlyLogEventPayloadTypes
        EarlyLogEventPayloadOnes EarlyLogEventPayloadTwos
        EarlyLogEventPayloadThrees EarlyLogEventPayloadFours
    )

    case "$Mode" in
        effective)
            [[ "${LoggingState[ConfigurationResolved]:-false}" == true ]] || return 80
            LoggingState[UseFallback]=false
            ;;
        fallback)
            [[ "${LoggingState[ConfigurationResolved]:-false}" != true ]] || return 80
            LoggingState[UseFallback]=true
            ;;
        *) return 80 ;;
    esac
    resolve_main_journal_path MainJournalPath || return $?
    for ArrayName in "${ParallelArrays[@]}"; do
        local -n ParallelArray="$ArrayName"
        (( ${#ParallelArray[@]} == Count )) || return 80
    done
    for ((Index=0; Index<Count; Index++)); do
        validate_journal_event \
            "${EarlyLogEventDomains[Index]}" "${EarlyLogEventRoles[Index]}" \
            "${EarlyLogEventDetails[Index]}" "${EarlyLogEventDeviceIds[Index]}" \
            "${EarlyLogEventMessageKeys[Index]}" "${EarlyLogEventResultCodes[Index]}" \
            "${EarlyLogEventKinds[Index]}" "${EarlyLogEventNumbers[Index]}" \
            "${EarlyLogEventBoundaries[Index]}" || return $?
        validate_log_payload "${EarlyLogEventPayloadTypes[Index]}" \
            "${EarlyLogEventPayloadOnes[Index]}" "${EarlyLogEventPayloadTwos[Index]}" \
            "${EarlyLogEventPayloadThrees[Index]}" \
            "${EarlyLogEventPayloadFours[Index]}" || return $?
    done

    LoggingState[FileRoutingReady]=true
    for ((Index=0; Index<Count; Index++)); do
        write_journal_event \
            "${EarlyLogEventDomains[Index]}" "${EarlyLogEventRoles[Index]}" \
            "${EarlyLogEventDetails[Index]}" "${EarlyLogEventDeviceIds[Index]}" \
            "${EarlyLogEventMessageKeys[Index]}" "${EarlyLogEventResultCodes[Index]}" \
            "${EarlyLogEventKinds[Index]}" "${EarlyLogEventNumbers[Index]}" \
            "${EarlyLogEventBoundaries[Index]}" "${EarlyLogEventPayloadTypes[Index]}" \
            "${EarlyLogEventPayloadOnes[Index]}" "${EarlyLogEventPayloadTwos[Index]}" \
            "${EarlyLogEventPayloadThrees[Index]}" \
            "${EarlyLogEventPayloadFours[Index]}" || return $?
    done
    EarlyLogEventDomains=()
    EarlyLogEventRoles=()
    EarlyLogEventDetails=()
    EarlyLogEventDeviceIds=()
    EarlyLogEventMessageKeys=()
    EarlyLogEventResultCodes=()
    EarlyLogEventKinds=()
    EarlyLogEventNumbers=()
    EarlyLogEventBoundaries=()
    EarlyLogEventPayloadTypes=()
    EarlyLogEventPayloadOnes=()
    EarlyLogEventPayloadTwos=()
    EarlyLogEventPayloadThrees=()
    EarlyLogEventPayloadFours=()
    return 0
}

# Назначение: Сопоставляет итоговый числовой код ключу локализованного сообщения для финального отчёта.
run_result_message_key()
{
    local Code="$1"
    local -n MessageKeyOut="$2"

    [[ "$Code" =~ ^(0|[1-9][0-9]*)$ ]] || return 80
    MessageKeyOut=result_unknown_failure

    case "$Code" in
        0) MessageKeyOut=result_success ;;
        1) MessageKeyOut=result_warning ;;
        12|2[0-5]|31) MessageKeyOut=result_invocation_failure ;;
        30) MessageKeyOut=result_dependency_failure ;;
        3[2-7]|6[1-5]) MessageKeyOut=result_storage_failure ;;
        40) MessageKeyOut=result_transport_failure ;;
        41) MessageKeyOut=result_authentication_failure ;;
        42) MessageKeyOut=result_remote_failure ;;
        43) MessageKeyOut=result_transfer_failure ;;
        50|52) MessageKeyOut=result_naming_failure ;;
        51|53|54) MessageKeyOut=result_artifact_failure ;;
        70|71) MessageKeyOut=result_archive_failure ;;
        80|81) MessageKeyOut=result_internal_failure ;;
    esac
    return 0
}

# Назначение: Возвращает локализованное имя класса success/warning/error для заданного результата.
# shellcheck disable=SC2034  # ClassOut is a nameref output.
localized_run_result_class()
{
    local Code="$1"
    local -n ClassOut="$2"
    local MessageKey=''

    run_result_message_key "$Code" MessageKey || return $?
    localized_message "$MessageKey" ClassOut
}

# Назначение: Выводит итог запуска с локализованным классом, сообщением и накопленными предупреждениями.
emit_backup_result_summary()
{
    local Code="$1"
    local ResultLabel=''
    local ResultClass=''

    [[ "$Code" =~ ^[0-9]+$ ]] || return 80
    localized_message backup_result ResultLabel
    localized_run_result_class "$Code" ResultClass
    if (( Code == 0 || Code == 1 )); then
        printf '%s: %s (%s)\n' "$ResultLabel" "$Code" "$ResultClass"
    else
        printf '%s: %s (%s)\n' "$ResultLabel" "$Code" "$ResultClass" >&2
    fi
    return 0
}

# ==============================================================================
# Cleanup registry, signals and terminal-safe unwinding
# ==============================================================================

# Назначение: Снимает тип, владельца и inode пути для последующей проверки, что cleanup удаляет именно созданный объект.
cleanup_path_identity()
{
    local Path="$1"
    local -n DeviceOut="$2"
    local -n InodeOut="$3"
    local Metadata=''
    local -a StatCommand=(stat -c '%d:%i' -- "$Path")

    Metadata="$(LC_ALL=C "${StatCommand[@]}" 2>/dev/null)" || return 35
    [[ "$Metadata" =~ ^[0-9]+:[0-9]+$ ]] || return 35
    DeviceOut="${Metadata%%:*}"
    InodeOut="${Metadata#*:}"
    return 0
}

# Назначение: Добавляет объект или дескриптор в реестр unwinding и выдаёт уникальный идентификатор записи через nameref.
# shellcheck disable=SC2034  # EntryIdOut is a nameref output.
register_cleanup_entry()
{
    local Type="$1"
    local Value="$2"
    local Owned="${3:-false}"
    local Device="${4:-}"
    local Inode="${5:-}"
    local -n EntryIdOut="$6"
    local Counter=$((${RuntimeState[CleanupEntryCounter]:-0} + 1))
    local GeneratedEntryId="CleanupEntry_$Counter"

    [[ "$Type" == file || "$Type" == directory || "$Type" == symlink || "$Type" == fd ]] || return 80
    [[ "$Owned" == true || "$Owned" == false ]] || return 80
    declare -gA "$GeneratedEntryId=()"
    local -n NewCleanupEntry="$GeneratedEntryId"
    NewCleanupEntry[Type]="$Type"
    NewCleanupEntry[Value]="$Value"
    NewCleanupEntry[Owned]="$Owned"
    NewCleanupEntry[Device]="$Device"
    NewCleanupEntry[Inode]="$Inode"
    # ShellCheck cannot resolve associative keys through a generated nameref.
    # shellcheck disable=SC2154
    NewCleanupEntry[Active]=true
    RuntimeState[CleanupEntryCounter]="$Counter"
    CleanupRegistry+=("$GeneratedEntryId")
    EntryIdOut="$GeneratedEntryId"
    return 0
}

# Назначение: Деактивирует конкретную запись cleanup, когда ресурс уже штатно освобождён владельцем.
unregister_cleanup_entry()
{
    local EntryId="$1"
    local Declaration=''

    Declaration="$(declare -p "$EntryId" 2>/dev/null)" || return 0
    [[ "$Declaration" == "declare -A $EntryId="* ]] || return 80
    local -n CleanupEntryToDisable="$EntryId"
    # Assignment is observable through the generated cleanup context.
    # shellcheck disable=SC2034
    CleanupEntryToDisable[Active]=false
    return 0
}

# Назначение: Снимает identity пути и регистрирует его для условного удаления только после подтверждения владения.
register_cleanup_path()
{
    local Path="$1"
    local EntryId=''
    local Device=''
    local Inode=''

    [[ -n "$Path" ]] || return 0
    cleanup_path_identity "$Path" Device Inode || return 35
    register_cleanup_entry file "$Path" true "$Device" "$Inode" EntryId || return $?
    return 0
}

# Назначение: Находит активную cleanup-запись заданного пути и снимает её с регистрации.
unregister_cleanup_path()
{
    local Path="$1"
    local EntryId
    local Declaration=''

    for EntryId in "${CleanupRegistry[@]}"; do
        Declaration="$(declare -p "$EntryId" 2>/dev/null)" || continue
        [[ "$Declaration" == "declare -A $EntryId="* ]] || continue
        local -n CleanupPathEntry="$EntryId"
        if [[ "${CleanupPathEntry[Active]:-false}" == true &&
              "${CleanupPathEntry[Value]}" == "$Path" ]]; then
            CleanupPathEntry[Active]=false
        fi
    done
    return 0
}

# Назначение: Помечает зарегистрированный путь как созданный процессом после успешного захвата права владения.
mark_cleanup_entry_owned()
{
    local EntryId="$1"
    local Device="$2"
    local Inode="$3"
    local -n CleanupEntryToOwn="$EntryId"

    [[ "${CleanupEntryToOwn[Active]:-false}" == true ]] || return 80
    CleanupEntryToOwn[Owned]=true
    CleanupEntryToOwn[Device]="$Device"
    CleanupEntryToOwn[Inode]="$Inode"
    return 0
}

# Назначение: Ставит открытый файловый дескриптор в общий реестр, чтобы сигнальный выход гарантированно его закрыл.
register_cleanup_fd()
{
    local Fd="$1"
    local EntryIdOutName="$2"

    [[ "$Fd" =~ ^[0-9]+$ ]] || return 80
    register_cleanup_entry fd "$Fd" true '' '' "$EntryIdOutName"
}

# Назначение: Проверяет совпадение текущего объекта пути с сохранёнными type/device/inode/owner перед удалением.
cleanup_entry_matches_path()
{
    local EntryId="$1"
    local -n CleanupMatchEntry="$EntryId"
    local ActualDevice=''
    local ActualInode=''

    [[ "${CleanupMatchEntry[Owned]:-false}" == true ]] || return 35
    cleanup_path_identity "${CleanupMatchEntry[Value]}" ActualDevice ActualInode || return 35
    [[ "$ActualDevice" == "${CleanupMatchEntry[Device]}" &&
       "$ActualInode" == "${CleanupMatchEntry[Inode]}" ]] || return 35
    if [[ -n "${CleanupMatchEntry[ReferenceFd]:-}" ]]; then
        local ReferenceFd="${CleanupMatchEntry[ReferenceFd]}"
        local ReferenceMetadata=''
        [[ "$ReferenceFd" =~ ^[0-9]+$ ]] || return 80
        ReferenceMetadata="$(LC_ALL=C stat -Lc '%d:%i' -- "/proc/${BASHPID}/fd/$ReferenceFd" 2>/dev/null)" || return 35
        [[ "$ReferenceMetadata" == "${CleanupMatchEntry[Device]}:${CleanupMatchEntry[Inode]}" ]] || return 35
    fi
    case "${CleanupMatchEntry[Type]}" in
        file) [[ -f "${CleanupMatchEntry[Value]}" && ! -L "${CleanupMatchEntry[Value]}" ]] || return 35 ;;
        directory) [[ -d "${CleanupMatchEntry[Value]}" && ! -L "${CleanupMatchEntry[Value]}" ]] || return 35 ;;
        symlink) [[ -L "${CleanupMatchEntry[Value]}" ]] || return 35 ;;
        *) return 80 ;;
    esac
    return 0
}

# Назначение: Возвращает сохранённые параметры tty и сбрасывает флаги терминального режима при любом завершении.
restore_terminal_state()
{
    local SavedState="${RuntimeState[TerminalSavedState]:-}"

    if [[ ("${RuntimeState[TerminalStateActive]:-false}" == true ||
           "${RuntimeState[TerminalTransitionPending]:-false}" == true) &&
          -n "$SavedState" ]]; then
        stty "$SavedState" <&0 2>/dev/null || return 1
    fi
    RuntimeState[TerminalStateActive]=false
    RuntimeState[TerminalTransitionPending]=false
    return 0
}

# Назначение: Один раз обходит реестр в обратном порядке, закрывает дескрипторы и удаляет только всё ещё принадлежащие процессу пути.
run_cleanup()
{
    local Index
    local EntryId
    local Declaration=''
    local Fd=0
    local -a RemoveCommand=()

    if [[ "${RuntimeState[CleanupDone]:-false}" == true ]]; then
        return 0
    fi
    RuntimeState[CleanupDone]=true

    stop_terminal_log_spinner || :
    restore_terminal_state || :

    for ((Index=${#CleanupRegistry[@]} - 1; Index >= 0; Index--)); do
        EntryId="${CleanupRegistry[Index]}"
        Declaration="$(declare -p "$EntryId" 2>/dev/null)" || continue
        [[ "$Declaration" == "declare -A $EntryId="* ]] || continue
        local -n CleanupRunEntry="$EntryId"
        [[ "${CleanupRunEntry[Active]:-false}" == true ]] || continue
        case "${CleanupRunEntry[Type]}" in
            fd)
                Fd="${CleanupRunEntry[Value]}"
                exec {Fd}>&-
                if [[ "${RuntimeState[PasswordChannelFd]:-}" == "$Fd" ]]; then
                    RuntimeState[PasswordChannelFd]=''
                fi
                if declare -F append_transport_trace >/dev/null 2>&1; then
                    append_transport_trace cleanup_fd_close
                fi
                ;;
            file)
                if cleanup_entry_matches_path "$EntryId"; then
                    RemoveCommand=(rm -f -- "${CleanupRunEntry[Value]}")
                    "${RemoveCommand[@]}" 2>/dev/null || :
                    if declare -F append_transport_trace >/dev/null 2>&1; then
                        append_transport_trace cleanup_path
                    fi
                fi
                if [[ -n "${CleanupRunEntry[ReferenceFd]:-}" ]]; then
                    Fd="${CleanupRunEntry[ReferenceFd]}"
                    if [[ "$Fd" =~ ^[0-9]+$ ]]; then
                        exec {Fd}>&-
                    fi
                    CleanupRunEntry[ReferenceFd]=''
                fi
                ;;
            symlink)
                if cleanup_entry_matches_path "$EntryId"; then
                    RemoveCommand=(rm -f -- "${CleanupRunEntry[Value]}")
                    "${RemoveCommand[@]}" 2>/dev/null || :
                    if declare -F append_transport_trace >/dev/null 2>&1; then
                        append_transport_trace cleanup_path
                    fi
                fi
                ;;
            directory)
                if cleanup_entry_matches_path "$EntryId"; then
                    RemoveCommand=(rmdir -- "${CleanupRunEntry[Value]}")
                    "${RemoveCommand[@]}" 2>/dev/null || :
                    if declare -F append_transport_trace >/dev/null 2>&1; then
                        append_transport_trace cleanup_path
                    fi
                fi
                ;;
        esac
        CleanupRunEntry[Active]=false
    done
    CleanupRegistry=()
    return 0
}

# Назначение: Запускает общий cleanup из EXIT trap, сохраняя исходный код завершения оболочки.
handle_exit()
{
    run_cleanup
}

# Назначение: Преобразует HUP/INT/TERM в канонический stop-код, завершает активный транспорт и выходит через общий cleanup.
handle_signal()
{
    local SignalName="$1"
    local ExitCode=143

    case "$SignalName" in
        HUP) ExitCode=129 ;;
        INT) ExitCode=130 ;;
        TERM) ExitCode=143 ;;
    esac

    terminate_active_transport_child || :
    # Cleanup belongs to EXIT so an interrupted Bash builtin can unwind its
    # private terminal state before the authoritative saved state is restored.
    trap 'run_cleanup' EXIT
    exit "$ExitCode"
}

# Назначение: Запоминает первый сигнал во время критической секции вместо немедленного разрушения создаваемого ресурса.
defer_runtime_signal()
{
    local SignalName="$1"

    if [[ -z "${RuntimeState[PendingSignal]:-}" ]]; then
        RuntimeState[PendingSignal]="$SignalName"
        if declare -F append_transport_trace >/dev/null 2>&1; then
            append_transport_trace "signal_deferred=$SignalName"
        fi
    fi
    return 0
}

# Назначение: Устанавливает рабочие HUP/INT/TERM traps после завершения начального bootstrap.
install_runtime_signal_traps()
{
    trap 'handle_signal HUP' HUP
    trap 'handle_signal INT' INT
    trap 'handle_signal TERM' TERM
    return 0
}

# Назначение: Подключает EXIT и ранние сигнальные traps для всего жизненного цикла процесса.
install_runtime_traps()
{
    trap handle_exit EXIT
    install_runtime_signal_traps
    return 0
}

# Назначение: Открывает короткую критическую секцию создания/регистрации ресурса, откладывая доставку runtime-сигнала.
begin_signal_deferral()
{
    [[ "${RuntimeState[SignalDeferral]:-false}" == false ]] || return 80
    RuntimeState[SignalDeferral]=true
    RuntimeState[PendingSignal]=''
    trap 'defer_runtime_signal HUP' HUP
    trap 'defer_runtime_signal INT' INT
    trap 'defer_runtime_signal TERM' TERM
    return 0
}

# Назначение: Закрывает критическую секцию и немедленно обрабатывает первый отложенный сигнал.
end_signal_deferral()
{
    local PendingSignal=''

    [[ "${RuntimeState[SignalDeferral]:-false}" == true ]] || return 80
    install_runtime_signal_traps || return 80
    PendingSignal="${RuntimeState[PendingSignal]:-}"
    RuntimeState[SignalDeferral]=false
    RuntimeState[PendingSignal]=''
    if [[ -n "$PendingSignal" ]]; then
        handle_signal "$PendingSignal"
    fi
    return 0
}

# ==============================================================================
# Localization and generic presentation services
# ==============================================================================

# Назначение: Заполняет встроенные EN/RU каталоги всеми сообщениями, подписями и текстами интерактивных экранов.
init_builtin_localization()
{
    MessagesEn[help_usage]='Usage: mikrotik-backup.sh [action] [options]'
    MessagesEn[help_long_option_forms]='Long options accept both --flag=value and --flag value.'
    MessagesEn[help_actions_title]='Actions:'
    MessagesEn[help_action_i]='-i  Interactive menu'
    MessagesEn[help_action_b]='-b  BackUP Master'
    MessagesEn[help_action_e]='-e  Configuration editor'
    MessagesEn[help_action_help]='-h, --help  Show help'
    MessagesEn[help_action_version]='-v, --version  Show version'
    MessagesEn[help_options_title]='Options:'
    MessagesEn[help_option_device_name]='--device-name NAME'
    MessagesEn[help_option_address]='-a=ADDRESS, --address ADDRESS'
    MessagesEn[help_option_user]='-u=USER, --user USER'
    MessagesEn[help_option_password]='-p=PASSWORD, --password PASSWORD'
    MessagesEn[help_option_port]='--port 1-65535'
    MessagesEn[help_option_language]='--language en|ru|auto'
    MessagesEn[help_option_use_oxidized]='--use-oxidized true|false'
    MessagesEn[help_option_oxidized_home]='--oxidized-home PATH'
    MessagesEn[help_option_use_identity_name]='--use-identity-name true|false'
    MessagesEn[help_option_backup_root]='--backup-root PATH'
    MessagesEn[help_option_use_net_folder]='--use-net-folder true|false'
    MessagesEn[help_option_monthly_archive]='--monthly-archive false|1..28'
    MessagesEn[help_option_log_level]='--log-level 0|1|2|3'
    MessagesEn[help_option_main_log_path]='--main-log-path PATH'
    MessagesEn[help_option_backup_type]='--backup-type configuration|binary|both'
    MessagesEn[help_option_export_format]='--export-format compact|terse|verbose'
    MessagesEn[help_option_show_sensitive]='--show-sensitive true|false'
    MessagesEn[help_option_encrypt]='--encrypt PASSWORD'
    MessagesEn[help_option_clear_dns_cache]='--clear-dns-cache true|false'
    MessagesEn[help_option_clear_console_history]='--clear-console-history true|false'
    MessagesEn[version]='MikroTik Backup Script'
    MessagesEn[action_conflict]='Conflicting actions were requested.'
    MessagesEn[invalid_cli]='Invalid parameter. Use --help to view supported commands.'
    MessagesEn[partial_single]='Missing required single-device fields:'
    MessagesEn[no_device_source]='No safe device-source object is available.'
    MessagesEn[missing_device_list]='DeviceList was not found or contains no runnable devices. Create it manually or run with -i and use BackUP Master.'
    MessagesEn[missing_dependency]='A required dependency is unavailable.'
    MessagesEn[not_implemented]='Live backup dispatch and artifact orchestration are beyond TASK-005.'
    MessagesEn[source_failure]='Device-source preparation failed.'
    MessagesEn[source_loaded]='Device source loaded (read/accepted/filtered/skipped):'
    MessagesEn[invalid_device_name]='The selected device name is invalid.'
    MessagesEn[duplicate_device_name]='The selected device name is already claimed.'
    MessagesEn[naming_locale_unavailable]='Required C.UTF-8 naming capability is unavailable.'
    MessagesEn[storage_failure]='Storage or lock preparation failed.'
    MessagesEn[transport_failure]='The SSH/SCP channel could not be established.'
    MessagesEn[authentication_failure]='Device authentication failed.'
    MessagesEn[remote_command_failure]='The remote command or output contract failed.'
    MessagesEn[transfer_failure]='The SCP file transfer failed.'
    MessagesEn[driver_contract_failure]='The embedded MikroTik driver contract is inconsistent.'
    MessagesEn[transport_capability_failure]='A mandatory local transport capability is unavailable.'
    MessagesEn[journal_script_sink_failure]='Unable to write main.log.'
    MessagesEn[journal_device_sink_failure]='Unable to write device journal.'
    MessagesEn[log_oxidized_source]='Obtaining device source from Oxidized'
    MessagesEn[log_oxidized_read_config]='Reading Oxidized configuration'
    MessagesEn[log_oxidized_import_database]='Importing Oxidized device database'
    MessagesEn[log_oxidized_publish_list]='Publishing generated device list'
    MessagesEn[log_device_list_loading]='Loading device list'
    MessagesEn[log_device_list_loaded]='Device list loaded: read {read}, accepted {accepted}, filtered {filtered}, skipped {skipped}'
    MessagesEn[log_batch_processing]='Batch device processing'
    MessagesEn[log_batch_device]='Processing device {index} of {total} — {device}'
    MessagesEn[log_batch_device_position]='Processing device {index} of {total}'
    MessagesEn[log_device_group]='Obtaining backups from device — {device}'
    MessagesEn[log_device_rsc_backup]='Obtaining RSC configuration backup'
    MessagesEn[log_device_binary_backup]='Obtaining binary backup'
    MessagesEn[log_device_monthly_archive]='Updating monthly archive'
    MessagesEn[log_device_clear_dns_cache]='Clearing DNS cache'
    MessagesEn[log_device_clear_console_history]='Clearing console history'
    MessagesEn[log_device_build_local_path]='Building local artifact path'
    MessagesEn[log_device_create_remote]='Creating remote backup result'
    MessagesEn[log_device_read_remote_size]='Reading remote result size'
    MessagesEn[log_device_prepare_local]='Preparing local destination'
    MessagesEn[log_device_fetch_file]='Fetching remote file'
    MessagesEn[log_device_validate_local]='Validating local artifact'
    MessagesEn[log_device_cleanup_local]='Removing failed local artifact'
    MessagesEn[log_device_cleanup_remote]='Removing remote temporary result'
    MessagesEn[log_device_retry_delay]='Waiting before retry'
    MessagesEn[log_device_incremental_compare]='Comparing incremental artifact'
    MessagesEn[menu_title]='Main menu'
    MessagesEn[menu_backup]='1. Start BackUP Master'
    MessagesEn[menu_batch]='2. Run batch backup'
    MessagesEn[menu_editor_create]='3. Script settings (Create option.cfg)'
    MessagesEn[menu_editor_edit]='3. Script settings (Edit option.cfg)'
    MessagesEn[menu_help]='4. CLI option reference'
    MessagesEn[menu_instruction]='5. Usage instructions'
    MessagesEn[menu_exit]='6. Exit'
    MessagesEn[menu_backup_hint]='Start the single-device workflow: create a backup, save the device to devicelist.cfg, or prepare a console command.'
    MessagesEn[menu_batch_hint]='Run batch backup for the devices discovered in devicelist.cfg.'
    MessagesEn[menu_editor_create_hint]='Create and perform the initial setup of option.cfg.'
    MessagesEn[menu_editor_edit_hint]='Review and change settings in option.cfg.'
    MessagesEn[menu_help_hint]='Description of command-line keys and parameters. The same help is available with -h and --help.'
    MessagesEn[menu_instruction_hint]='Description of how this script works.'
    MessagesEn[menu_exit_hint]='Finish the script and return to the console.'
    MessagesEn[help_title]='CLI option reference'
    MessagesEn[instruction_title]='Usage instructions'
    MessagesEn[document_return]='0. Return to Main menu'
    MessagesEn[document_exit]='6. Exit'
    MessagesEn[help_return_hint]="Return to the script's main action selection."
    MessagesEn[help_exit_hint]='Exit to the console.'
    MessagesEn[page_label]='Page'
    MessagesEn[page_scroll]='scroll'
    MessagesEn[terminal_geometry_error]='Terminal is too small (actual/required):'
    MessagesEn[option_passport_file]='# File: option.cfg'
    MessagesEn[option_passport_purpose]='# Purpose: script settings'
    MessagesEn[device_passport_file]='# File: devicelist.cfg'
    MessagesEn[device_passport_purpose]='# Purpose: device list for batch backup'
    MessagesEn[editor_title]='Configuration editor'
    MessagesEn[editor_save]='Save'
    MessagesEn[editor_cancel]='Cancel'
    MessagesEn[editor_discard]='Discard staged changes?'
    MessagesEn[yes]='Yes'
    MessagesEn[no]='No'
    MessagesEn[input_prompt]='Enter value'
    MessagesEn[invalid_input]='Invalid value. Try again.'
    MessagesEn[save_failed]='Configuration save failed.'
    MessagesEn[description_language]='Interface and log language. With auto, the system environment language will be used.'
    MessagesEn[description_use_oxidized]='If the Oxidized service is installed, the device list can be obtained from its configuration.'
    MessagesEn[description_oxidized_home]='Path to the Oxidized service working directory.'
    MessagesEn[description_use_identity_name]=$'Uses the device\'s RouterOS Identity when forming the backup name. If set to “No”, the name from devicelist.cfg will be used.'
    MessagesEn[description_backup_type]='Determines what to create: a configuration export, a binary Backup, or both.'
    MessagesEn[description_use_incremental]='When enabled, compares each new backup with the previous artifact and applies incremental retention. When disabled, skips that comparison and keeps every new valid backup.'
    MessagesEn[description_export_format]='Selects the RouterOS text export format: Compact, Terse, or Verbose.'
    MessagesEn[description_show_sensitive]='Includes sensitive data such as passwords in the configuration export.'
    MessagesEn[description_encrypt]='Sets the binary Backup encryption password. An empty value means an unencrypted archive.'
    MessagesEn[description_clear_dns_cache]='Clears the device DNS cache before creating a binary backup.'
    MessagesEn[description_clear_console_history]='Clears the RouterOS command history before creating a binary backup.'
    MessagesEn[description_backup_root]='The main directory where the script stores device backups.'
    MessagesEn[description_use_net_folder]='Enables checks of the directory above as network backup storage.'
    MessagesEn[description_monthly_archive]='Disables monthly archiving or selects local day 1-28. Any time that day is accepted; missed days are not caught up. The ZIP is named for the preceding calendar day.'
    MessagesEn[description_log_level]='Controls logging detail from 0 (errors only) through 3 (full terminal and journal detail).'
    MessagesEn[description_main_log_path]='Directory for main.log. Empty follows the effective BackupRoot; a relative path is resolved beside the script.'
    MessagesEn[description_save]='Saves the current settings to option.cfg and finishes editing.'
    MessagesEn[description_cancel]='Exits the editor without saving the changes.'
    MessagesEn[comment_ssh_port]='Default SSH port for connecting to devices.'
    MessagesEn[comment_ignore_oxi_access]='Allows use of the existing devicelist.cfg when Oxidized data is unavailable.'
    MessagesEn[comment_encrypt_type]='Binary Backup encryption algorithm. Internal setting: aes-sha256.'
    MessagesEn[comment_login]='Compatible default login. Preserved only when this setting is present.'
    MessagesEn[comment_password]='Compatible default password. Preserved only when this setting is present.'
    MessagesEn[wizard_title]='BackUP Master'
    MessagesEn[wizard_summary]='Summary'
    MessagesEn[wizard_confirm]='Confirm'
    MessagesEn[wizard_edit]='Edit'
    MessagesEn[wizard_cancel]='Cancel'
    MessagesEn[value_set]='[set]'
    MessagesEn[value_not_set]='[not set]'
    MessagesEn[backup_result]='Backup result'
    MessagesEn[result_success]='success'
    MessagesEn[result_warning]='completed with warnings'
    MessagesEn[result_invocation_failure]='invocation or configuration error'
    MessagesEn[result_dependency_failure]='dependency or capability error'
    MessagesEn[result_storage_failure]='storage or locking error'
    MessagesEn[result_transport_failure]='transport error'
    MessagesEn[result_authentication_failure]='authentication error'
    MessagesEn[result_remote_failure]='remote command or output error'
    MessagesEn[result_transfer_failure]='file transfer error'
    MessagesEn[result_naming_failure]='device naming error'
    MessagesEn[result_artifact_failure]='backup artifact error'
    MessagesEn[result_archive_failure]='archive error'
    MessagesEn[result_internal_failure]='internal error'
    MessagesEn[result_unknown_failure]='backup error'
    MessagesEn[field_language]='Language'
    MessagesEn[field_ssh_port]='SSH port'
    MessagesEn[field_use_oxidized]='Use Oxidized'
    MessagesEn[field_oxidized_home]='Oxidized home'
    MessagesEn[field_use_identity_name]='Use identity name'
    MessagesEn[field_backup_root]='Backup directory'
    MessagesEn[field_use_net_folder]='This is a network directory'
    MessagesEn[field_monthly_archive]='Monthly archive'
    MessagesEn[field_log_level]='Log level'
    MessagesEn[field_main_log_path]='Main log directory'
    MessagesEn[field_address]='Address'
    MessagesEn[field_user]='User'
    MessagesEn[field_password]='Password'
    MessagesEn[field_device_name]='Device Name'
    MessagesEn[field_ignore_oxi_access]='Ignore Oxidized access failures'
    MessagesEn[field_backup_type]='Backup type'
    MessagesEn[field_use_incremental]='Use incremental backups'
    MessagesEn[field_export_format]='Export format'
    MessagesEn[field_show_sensitive]='Sensitive data'
    MessagesEn[field_encrypt]='Archive encryption'
    MessagesEn[field_clear_dns_cache]='DNS cache cleanup'
    MessagesEn[field_clear_console_history]='Console history cleanup'
    MessagesEn[value_configuration]='Configuration'
    MessagesEn[value_binary]='Binary'
    MessagesEn[value_both]='Both'
    MessagesEn[value_compact]='Compact'
    MessagesEn[value_terse]='Terse'
    MessagesEn[value_verbose]='Verbose'
    MessagesEn[value_disabled]='disabled'
    MessagesEn[master_execute]='1. Execute backup'
    MessagesEn[master_save_device]='2. Save device to devicelist.cfg'
    MessagesEn[master_copy_cli]='3. Copy console command'
    MessagesEn[master_return]='0. Return to Main Menu'
    MessagesEn[master_field_device_name]='Device name'
    MessagesEn[master_field_address]='IP address'
    MessagesEn[master_field_user]='User'
    MessagesEn[master_field_password]='Password'
    MessagesEn[master_field_ssh_port]='SSH port'
    MessagesEn[master_field_backup_type]='Backup type'
    MessagesEn[master_field_use_incremental]='Use incremental backups'
    MessagesEn[master_field_export_format]='Export format'
    MessagesEn[master_field_show_sensitive]='Sensitive data'
    MessagesEn[master_field_encrypt]='Encryption password'
    MessagesEn[master_field_clear_dns_cache]='Clear DNS cache'
    MessagesEn[master_field_clear_console_history]='Clear console history'
    MessagesEn[master_field_backup_root]='Backup directory'
    MessagesEn[master_field_use_net_folder]='This is a network directory'
    MessagesEn[master_field_use_identity_name]='Use RouterOS Identity'
    MessagesEn[master_description_device_name]='Device name for devicelist.cfg and for the backup name when RouterOS Identity is not used.'
    MessagesEn[master_description_address]='IP address or host name of the MikroTik device.'
    MessagesEn[master_description_user]='Login used to connect to the device.'
    MessagesEn[master_description_password]='Password used to connect to the device.'
    MessagesEn[master_description_ssh_port]='SSH port used to connect to the device.'
    MessagesEn[master_description_execute]='Executes a backup with the parameters in the current form.'
    MessagesEn[master_description_save]='Saves the device connection data to devicelist.cfg.'
    MessagesEn[master_description_copy]='Copies the console command to the clipboard and exits to the console.'
    MessagesEn[master_description_return]='Returns to Main Menu without saving the temporary form.'
    MessagesEn[master_device_saved]='DeviceList was updated.'
    MessagesEn[master_device_conflict]='The device conflicts with another DeviceList record.'
    MessagesEn[instruction_01]='How MikroTik Backup Script works'
    MessagesEn[instruction_02]='Purpose:'
    MessagesEn[instruction_03]='This script creates RouterOS backups.'
    MessagesEn[instruction_04]='It can operate in two main modes:'
    MessagesEn[instruction_05]='- with one device through the interactive Master or command line;'
    MessagesEn[instruction_06]='- with several devices in batch mode.'
    MessagesEn[instruction_07]='Depending on the settings, two kinds of backups can be created:'
    MessagesEn[instruction_08]='- RouterOS configuration in an .rsc file;'
    MessagesEn[instruction_09]='- Binary backup in a .backup file;'
    MessagesEn[instruction_10]='Script settings'
    MessagesEn[instruction_11]='All parameters required by the script are built into it.'
    MessagesEn[instruction_12]='Some are optional and can be changed using option.cfg in the same directory as the script.'
    MessagesEn[instruction_13]='It can define the backup directory, device-list source, backup types, monthly archiving, incrementality and other common parameters.'
    MessagesEn[instruction_14]='option.cfg can be created manually or with the editor started by this key:'
    MessagesEn[instruction_15]='./mikrotik-backup.sh -e'
    MessagesEn[instruction_16]='Command-line mode'
    MessagesEn[instruction_17]='At minimum, only three parameters are required: IP address, login and password.'
    MessagesEn[instruction_18]='./mikrotik-backup.sh -a=xxx.xxx.xxx.xxx -u=user -p=password'
    MessagesEn[instruction_19]='The remaining command-line parameters are optional.'
    MessagesEn[instruction_20]='Display their reference with:'
    MessagesEn[instruction_21]='./mikrotik-backup.sh -h'
    MessagesEn[instruction_22]='Batch mode'
    MessagesEn[instruction_23]='This mode requires devicelist.cfg in the same directory as the script. List device names and connection data in that file.'
    MessagesEn[instruction_24]='Create the file manually or use BackUP Master.'
    MessagesEn[instruction_25]='Where to find backups'
    MessagesEn[instruction_26]='The storage directory is set by BackupRoot in option.cfg.'
    MessagesEn[instruction_27]='If BackupRoot is absent, or option.cfg has not been created, device backups are placed in the backups directory next to mikrotik-backup.sh.'
    MessagesEn[instruction_28]='If BackupRoot points to network storage, set UseNetFolder=true. This enables availability checks before backups are created.'

    MessagesRu[help_usage]='Использование: mikrotik-backup.sh [действие] [параметры]'
    MessagesRu[help_long_option_forms]='Длинные параметры принимают обе формы: --flag=value и --flag value.'
    MessagesRu[help_actions_title]='Действия:'
    MessagesRu[help_action_i]='-i  Интерактивное меню'
    MessagesRu[help_action_b]='-b  Мастер резервного копирования'
    MessagesRu[help_action_e]='-e  Редактор конфигурации'
    MessagesRu[help_action_help]='-h, --help  Показать справку'
    MessagesRu[help_action_version]='-v, --version  Показать версию'
    MessagesRu[help_options_title]='Параметры:'
    MessagesRu[help_option_device_name]='--device-name ИМЯ'
    MessagesRu[help_option_address]='-a=АДРЕС, --address АДРЕС'
    MessagesRu[help_option_user]='-u=ЛОГИН, --user ЛОГИН'
    MessagesRu[help_option_password]='-p=ПАРОЛЬ, --password ПАРОЛЬ'
    MessagesRu[help_option_port]='--port 1-65535'
    MessagesRu[help_option_language]='--language en|ru|auto'
    MessagesRu[help_option_use_oxidized]='--use-oxidized true|false'
    MessagesRu[help_option_oxidized_home]='--oxidized-home ПУТЬ'
    MessagesRu[help_option_use_identity_name]='--use-identity-name true|false'
    MessagesRu[help_option_backup_root]='--backup-root ПУТЬ'
    MessagesRu[help_option_use_net_folder]='--use-net-folder true|false'
    MessagesRu[help_option_monthly_archive]='--monthly-archive false|1..28'
    MessagesRu[help_option_log_level]='--log-level 0|1|2|3'
    MessagesRu[help_option_main_log_path]='--main-log-path ПУТЬ'
    MessagesRu[help_option_backup_type]='--backup-type configuration|binary|both'
    MessagesRu[help_option_export_format]='--export-format compact|terse|verbose'
    MessagesRu[help_option_show_sensitive]='--show-sensitive true|false'
    MessagesRu[help_option_encrypt]='--encrypt ПАРОЛЬ'
    MessagesRu[help_option_clear_dns_cache]='--clear-dns-cache true|false'
    MessagesRu[help_option_clear_console_history]='--clear-console-history true|false'
    MessagesRu[version]='Резервное копирование MikroTik'
    MessagesRu[action_conflict]='Запрошены конфликтующие действия.'
    MessagesRu[invalid_cli]='Неверный параметр. Воспользуйтесь --help для просмотра возможных команд.'
    MessagesRu[partial_single]='Не указаны обязательные поля одного устройства:'
    MessagesRu[no_device_source]='Безопасный объект источника устройств недоступен.'
    MessagesRu[missing_device_list]='Не обнаружен DeviceList с доступными для запуска устройствами. Создайте файл вручную или запустите скрипт с ключом -i и воспользуйтесь пунктом «Мастер резервного копирования».'
    MessagesRu[missing_dependency]='Обязательная зависимость недоступна.'
    MessagesRu[not_implemented]='Рабочий запуск резервного копирования и оркестрация артефактов находятся за границей TASK-005.'
    MessagesRu[source_failure]='Ошибка подготовки источника устройств.'
    MessagesRu[source_loaded]='Источник устройств загружен (прочитано/принято/отфильтровано/пропущено):'
    MessagesRu[invalid_device_name]='Выбранное имя устройства недопустимо.'
    MessagesRu[duplicate_device_name]='Выбранное имя устройства уже используется.'
    MessagesRu[naming_locale_unavailable]='Требуемые возможности локали C.UTF-8 для имён недоступны.'
    MessagesRu[storage_failure]='Ошибка подготовки хранилища или блокировки.'
    MessagesRu[transport_failure]='Не удалось установить канал SSH/SCP.'
    MessagesRu[authentication_failure]='Ошибка аутентификации устройства.'
    MessagesRu[remote_command_failure]='Ошибка удалённой команды или контракта вывода.'
    MessagesRu[transfer_failure]='Ошибка передачи файла по SCP.'
    MessagesRu[driver_contract_failure]='Нарушен контракт встроенного драйвера MikroTik.'
    MessagesRu[transport_capability_failure]='Недоступна обязательная локальная возможность транспорта.'
    MessagesRu[journal_script_sink_failure]='Не удалось записать main.log.'
    MessagesRu[journal_device_sink_failure]='Не удалось записать журнал устройства.'
    MessagesRu[log_oxidized_source]='Получение источника устройств из Oxidized'
    MessagesRu[log_oxidized_read_config]='Чтение конфигурации Oxidized'
    MessagesRu[log_oxidized_import_database]='Импорт базы устройств Oxidized'
    MessagesRu[log_oxidized_publish_list]='Публикация созданного списка устройств'
    MessagesRu[log_device_list_loading]='Загрузка списка устройств'
    MessagesRu[log_device_list_loaded]='Список устройств загружен: прочитано {read}, принято {accepted}, отфильтровано {filtered}, пропущено {skipped}'
    MessagesRu[log_batch_processing]='Пакетная обработка устройств'
    MessagesRu[log_batch_device]='Обработка устройства {index} из {total} — {device}'
    MessagesRu[log_batch_device_position]='Обработка устройства {index} из {total}'
    MessagesRu[log_device_group]='Получение резервных копий с устройства — {device}'
    MessagesRu[log_device_rsc_backup]='Получение конфигурационного бэкапа RSC'
    MessagesRu[log_device_binary_backup]='Получение бинарного бэкапа'
    MessagesRu[log_device_monthly_archive]='Обновление ежемесячного архива'
    MessagesRu[log_device_clear_dns_cache]='Очистка кэша DNS'
    MessagesRu[log_device_clear_console_history]='Очистка истории консоли'
    MessagesRu[log_device_build_local_path]='Формирование пути локального артефакта'
    MessagesRu[log_device_create_remote]='Создание удалённого результата резервного копирования'
    MessagesRu[log_device_read_remote_size]='Чтение размера удалённого результата'
    MessagesRu[log_device_prepare_local]='Подготовка локального назначения'
    MessagesRu[log_device_fetch_file]='Получение удалённого файла'
    MessagesRu[log_device_validate_local]='Проверка локального артефакта'
    MessagesRu[log_device_cleanup_local]='Удаление локального артефакта неудачной попытки'
    MessagesRu[log_device_cleanup_remote]='Удаление временного удалённого результата'
    MessagesRu[log_device_retry_delay]='Ожидание перед повторной попыткой'
    MessagesRu[log_device_incremental_compare]='Сравнение инкрементального артефакта'
    MessagesRu[menu_title]='Главное меню'
    MessagesRu[menu_backup]='1. Запуск мастера резервного копирования'
    MessagesRu[menu_batch]='2. Выполнить пакетное копирование'
    MessagesRu[menu_editor_create]='3. Настройка скрипта (Создание option.cfg)'
    MessagesRu[menu_editor_edit]='3. Настройка скрипта (Редактор option.cfg)'
    MessagesRu[menu_help]='4. Справка по ключам CLI'
    MessagesRu[menu_instruction]='5. Инструкция по использованию'
    MessagesRu[menu_exit]='6. Выход'
    MessagesRu[menu_backup_hint]='Запуск мастера работы с единичным устройством: выполнить резервное копирование, сохранить устройство в devicelist.cfg, подготовить консольную команду.'
    MessagesRu[menu_batch_hint]='Запуск пакетного резервного копирования устройств, обнаруженных в devicelist.cfg.'
    MessagesRu[menu_editor_create_hint]='Создание и первоначальная настройка файла option.cfg.'
    MessagesRu[menu_editor_edit_hint]='Просмотр и изменение настроек в файле option.cfg.'
    MessagesRu[menu_help_hint]='Описание ключей и параметров командной строки. Эта же справка доступна по ключам -h и --help.'
    MessagesRu[menu_instruction_hint]='Описание принципов работы данного скрипта.'
    MessagesRu[menu_exit_hint]='Завершение работы скрипта и выход в консоль.'
    MessagesRu[help_title]='Справка по ключам CLI'
    MessagesRu[instruction_title]='Инструкция по использованию'
    MessagesRu[document_return]='0. Вернуться в Главное меню'
    MessagesRu[document_exit]='6. Выход'
    MessagesRu[help_return_hint]='Возврат к выбору основных действий скрипта.'
    MessagesRu[help_exit_hint]='Выход в консоль.'
    MessagesRu[page_label]='Страница'
    MessagesRu[page_scroll]='листать'
    MessagesRu[terminal_geometry_error]='Недостаточный размер терминала (фактический/требуемый):'
    MessagesRu[option_passport_file]='# Файл: option.cfg'
    MessagesRu[option_passport_purpose]='# Назначение: настройки скрипта'
    MessagesRu[device_passport_file]='# Файл: devicelist.cfg'
    MessagesRu[device_passport_purpose]='# Назначение: список устройств для копирования'
    MessagesRu[editor_title]='Редактор конфигурации'
    MessagesRu[editor_save]='Сохранить'
    MessagesRu[editor_cancel]='Отмена'
    MessagesRu[editor_discard]='Отменить подготовленные изменения?'
    MessagesRu[yes]='Да'
    MessagesRu[no]='Нет'
    MessagesRu[input_prompt]='Введите значение'
    MessagesRu[invalid_input]='Недопустимое значение. Повторите ввод.'
    MessagesRu[save_failed]='Не удалось сохранить конфигурацию.'
    MessagesRu[description_language]='Язык интерфейса и логов. При auto будет использован язык окружения системы.'
    MessagesRu[description_use_oxidized]='Если установлен сервис Oxidized, можно получить список устройств из его конфигурации.'
    MessagesRu[description_oxidized_home]='Путь к рабочему каталогу сервиса Oxidized.'
    MessagesRu[description_use_identity_name]='Использует RouterOS Identity устройства при формировании имени резервной копии. Если «Нет», будет использовано имя из devicelist.cfg.'
    MessagesRu[description_backup_type]='Определяет, что создавать: экспорт конфигурации, бинарный Backup или оба варианта.'
    MessagesRu[description_use_incremental]='Если включено, сравнивает каждую новую резервную копию с предыдущим артефактом и применяет инкрементальную политику хранения. Если выключено, пропускает сравнение и сохраняет каждую новую валидную резервную копию.'
    MessagesRu[description_export_format]='Выбирает формат текстового экспорта RouterOS: Compact, Terse или Verbose.'
    MessagesRu[description_show_sensitive]='Включает в экспорт конфигурации чувствительные данные: пароли и т. п.'
    MessagesRu[description_encrypt]='Задаёт пароль шифрования бинарного Backup. Пустое значение означает архив без шифрования.'
    MessagesRu[description_clear_dns_cache]='Очищает DNS-кэш устройства перед созданием бинарной резервной копии.'
    MessagesRu[description_clear_console_history]='Очищает историю команд RouterOS перед созданием бинарной резервной копии.'
    MessagesRu[description_backup_root]='Основной каталог, внутри которого скрипт хранит резервные копии устройств.'
    MessagesRu[description_use_net_folder]='Включает проверки указанного выше каталога как сетевого хранилища резервных копий.'
    MessagesRu[description_monthly_archive]='Отключает месячную архивацию или выбирает локальное число 1-28. Допустимо любое время этого дня; пропущенный день не догоняется. ZIP получает имя предыдущей календарной даты.'
    MessagesRu[description_log_level]='Задаёт детализацию логов от 0 (только ошибки) до 3 (полная детализация терминала и журналов).'
    MessagesRu[description_main_log_path]='Каталог для main.log. Пустое значение следует за действующим BackupRoot; относительный путь разрешается рядом со скриптом.'
    MessagesRu[description_save]='Сохраняет текущие настройки в option.cfg и завершает редактирование.'
    MessagesRu[description_cancel]='Выход из редактора без сохранения сделанных изменений.'
    MessagesRu[comment_ssh_port]='SSH-порт по умолчанию для подключения к устройствам.'
    MessagesRu[comment_ignore_oxi_access]='Разрешает использовать существующий devicelist.cfg, если данные Oxidized недоступны.'
    MessagesRu[comment_encrypt_type]='Алгоритм шифрования бинарного Backup. Служебная настройка: aes-sha256.'
    MessagesRu[comment_login]='Совместимый логин по умолчанию. Сохраняется только при наличии этой настройки.'
    MessagesRu[comment_password]='Совместимый пароль по умолчанию. Сохраняется только при наличии этой настройки.'
    MessagesRu[wizard_title]='Мастер резервного копирования'
    MessagesRu[wizard_summary]='Сводка'
    MessagesRu[wizard_confirm]='Выполнить'
    MessagesRu[wizard_edit]='Изменить'
    MessagesRu[wizard_cancel]='Отмена'
    MessagesRu[value_set]='[задан]'
    MessagesRu[value_not_set]='[не задан]'
    MessagesRu[backup_result]='Результат резервного копирования'
    MessagesRu[result_success]='успешно'
    MessagesRu[result_warning]='завершено с предупреждениями'
    MessagesRu[result_invocation_failure]='ошибка параметров или конфигурации'
    MessagesRu[result_dependency_failure]='ошибка зависимости или возможности среды'
    MessagesRu[result_storage_failure]='ошибка хранилища или блокировки'
    MessagesRu[result_transport_failure]='ошибка транспорта'
    MessagesRu[result_authentication_failure]='ошибка аутентификации'
    MessagesRu[result_remote_failure]='ошибка удалённой команды или вывода'
    MessagesRu[result_transfer_failure]='ошибка передачи файла'
    MessagesRu[result_naming_failure]='ошибка имени устройства'
    MessagesRu[result_artifact_failure]='ошибка артефакта резервной копии'
    MessagesRu[result_archive_failure]='ошибка архива'
    MessagesRu[result_internal_failure]='внутренняя ошибка'
    MessagesRu[result_unknown_failure]='ошибка резервного копирования'
    MessagesRu[field_language]='Язык'
    MessagesRu[field_ssh_port]='Порт SSH'
    MessagesRu[field_use_oxidized]='Использовать Oxidized'
    MessagesRu[field_oxidized_home]='Каталог Oxidized'
    MessagesRu[field_use_identity_name]='Использовать Identity в имени'
    MessagesRu[field_backup_root]='Каталог резервных копий'
    MessagesRu[field_use_net_folder]='Это сетевой каталог'
    MessagesRu[field_monthly_archive]='Ежемесячный архив'
    MessagesRu[field_log_level]='Уровень логов'
    MessagesRu[field_main_log_path]='Каталог основного лога'
    MessagesRu[field_address]='Адрес'
    MessagesRu[field_user]='Пользователь'
    MessagesRu[field_password]='Пароль'
    MessagesRu[field_device_name]='Имя устройства'
    MessagesRu[field_ignore_oxi_access]='Игнорировать недоступность Oxidized'
    MessagesRu[field_backup_type]='Тип архива'
    MessagesRu[field_use_incremental]='Использовать инкрементальное сравнение'
    MessagesRu[field_export_format]='Формат экспорта'
    MessagesRu[field_show_sensitive]='Чувствительные данные'
    MessagesRu[field_encrypt]='Шифр архива'
    MessagesRu[field_clear_dns_cache]='Очистка DNS кэша'
    MessagesRu[field_clear_console_history]='Очистка истории консоли'
    MessagesRu[value_configuration]='Конфигурация'
    MessagesRu[value_binary]='Бинарный'
    MessagesRu[value_both]='Оба'
    MessagesRu[value_compact]='Compact'
    MessagesRu[value_terse]='Terse'
    MessagesRu[value_verbose]='Verbose'
    MessagesRu[value_disabled]='отключено'
    MessagesRu[master_execute]='1. Выполнить резервное копирование'
    MessagesRu[master_save_device]='2. Сохранить устройство в devicelist.cfg'
    MessagesRu[master_copy_cli]='3. Скопировать консольную команду'
    MessagesRu[master_return]='0. Вернуться в Главное меню'
    MessagesRu[master_field_device_name]='Имя устройства'
    MessagesRu[master_field_address]='IP-адрес'
    MessagesRu[master_field_user]='Логин'
    MessagesRu[master_field_password]='Пароль'
    MessagesRu[master_field_ssh_port]='SSH-порт'
    MessagesRu[master_field_backup_type]='Тип резервной копии'
    MessagesRu[master_field_use_incremental]='Использовать инкрементальное сравнение'
    MessagesRu[master_field_export_format]='Формат экспорта'
    MessagesRu[master_field_show_sensitive]='Чувствительные данные'
    MessagesRu[master_field_encrypt]='Пароль шифрования'
    MessagesRu[master_field_clear_dns_cache]='Очистка DNS-кэша'
    MessagesRu[master_field_clear_console_history]='Очистка истории консоли'
    MessagesRu[master_field_backup_root]='Каталог резервных копий'
    MessagesRu[master_field_use_net_folder]='Это сетевой каталог'
    MessagesRu[master_field_use_identity_name]='Использовать RouterOS Identity'
    MessagesRu[master_description_device_name]='Имя устройства для devicelist.cfg и имени резервной копии, когда RouterOS Identity не используется.'
    MessagesRu[master_description_address]='IP-адрес или имя узла устройства MikroTik.'
    MessagesRu[master_description_user]='Логин для подключения к устройству.'
    MessagesRu[master_description_password]='Пароль для подключения к устройству.'
    MessagesRu[master_description_ssh_port]='SSH-порт для подключения к устройству.'
    MessagesRu[master_description_execute]='Выполнение резервного копирования с параметрами текущей формы.'
    MessagesRu[master_description_save]='Сохранение данных подключения устройства в devicelist.cfg.'
    MessagesRu[master_description_copy]='Копирование консольной команды в буфер обмена и выход в консоль.'
    MessagesRu[master_description_return]='Возврат в Главное меню без сохранения временной формы.'
    MessagesRu[master_device_saved]='DeviceList обновлён.'
    MessagesRu[master_device_conflict]='Устройство конфликтует с другой записью DeviceList.'
    MessagesRu[instruction_01]='Описание работы MikroTik Backup Script'
    MessagesRu[instruction_02]='Назначение:'
    MessagesRu[instruction_03]='Данный скрипт предназначен для создания резервных копий RouterOS.'
    MessagesRu[instruction_04]='Работа может быть осуществлена в двух основных режимах:'
    MessagesRu[instruction_05]='- с одним устройством через интерактивный Мастер или командную строку;'
    MessagesRu[instruction_06]='- с несколькими устройствами в пакетном режиме.'
    MessagesRu[instruction_07]='В зависимости от настроек могут быть созданы два вида резервных копий:'
    MessagesRu[instruction_08]='- Конфигурация RouterOS в файл .rsc;'
    MessagesRu[instruction_09]='- Бинарная резервная копия в файл .backup;'
    MessagesRu[instruction_10]='Настройки скрипта'
    MessagesRu[instruction_11]='Все параметры необходимые для работы скрипта вшиты в его структуру.'
    MessagesRu[instruction_12]='Некоторые из них опциональны и могут быть изменены с помощью файла option.cfg который следует расположить в том же каталоге что и сам скрипт.'
    MessagesRu[instruction_13]='В нём можно определить, каталог хранения резервных копий, источник перечня устройств, типы резервных копий, включить ежемесячное архивирование, инкрементацию и некоторые другие общие параметры.'
    MessagesRu[instruction_14]='Файл option.cfg можно создать как вручную, так и с помощью мастера вызываемого с помощью ключа запуска'
    MessagesRu[instruction_15]='./mikrotik-backup.sh -e'
    MessagesRu[instruction_16]='Запуск в режиме командной строки'
    MessagesRu[instruction_17]='Минимально необходимо указать лишь три параметра: IP Адрес, Логин, Пароль.'
    MessagesRu[instruction_18]='./mikrotik-backup.sh -a=xxx.xxx.xxx.xxx -u=user -p=password'
    MessagesRu[instruction_19]='Остальные параметры командной строки являются опциональными.'
    MessagesRu[instruction_20]='Получить по ним справку можно при прямом запуске:'
    MessagesRu[instruction_21]='./mikrotik-backup.sh -h'
    MessagesRu[instruction_22]='Запуск в режиме пакетной обработки'
    MessagesRu[instruction_23]='Для данного режима работы требуется файл со списком устройств devicelist.cfg который следует расположить в том же каталоге что и сам скрипт. В данном файле необходимо перечислить имена устройств и данные о подключении к ним.'
    MessagesRu[instruction_24]='Файл можно создать вручную либо воспользоваться «Мастером резервного копирования».'
    MessagesRu[instruction_25]='Где искать резервные копии'
    MessagesRu[instruction_26]='Каталог хранения задаётся параметром BackupRoot в option.cfg.'
    MessagesRu[instruction_27]='Если данный параметр не указан, либо файл option.cfg не создан. Резервные копии устройств будут созданы в каталоге backups, расположенном там же, где находится сам mikrotik-backup.sh'
    MessagesRu[instruction_28]='Если каталог определенный в переменной BackupRoot является сетевым, необходимо установить значение переменной UseNetFolder=true Это включит проверки доступности данного каталога перед тем как будут создаваться резервные копии.'
    return 0
}

# Назначение: Приводит код языка к каноническому виду и отвергает небезопасные идентификаторы внешних каталогов.
# shellcheck disable=SC2034  # NormalizedOut is a nameref output.
normalize_language_identifier()
{
    local InputValue="$1"
    local -n NormalizedOut="$2"

    if [[ "$InputValue" == auto ]]; then
        NormalizedOut=auto
        return 0
    fi
    [[ "$InputValue" =~ ^[A-Za-z]{2}$ ]] || return 12
    NormalizedOut="${InputValue,,}"
    return 0
}

# Назначение: Находит допустимые *.lang рядом с программой и возвращает отсортированный список доступных языков.
# shellcheck disable=SC2034  # CodesOut is a nameref output.
discover_external_language_codes()
{
    local -n CodesOut="$1"
    local Directory="${RuntimeState[ProgramDirectory]}"
    local Path=''
    local BaseName=''
    local Code=''
    local Existing=''
    local Position=0
    local -A DiscoveredCodesSeen=()
    local -a SortedCodes=()
    local LC_ALL=C

    CodesOut=()
    for Path in "$Directory"/*; do
        [[ -f "$Path" && ! -L "$Path" && -r "$Path" ]] || continue
        BaseName="${Path##*/}"
        [[ "$BaseName" =~ ^([A-Za-z]{2})\.lang$ ]] || continue
        Code="${BASH_REMATCH[1],,}"
        [[ "$Code" != en && "$Code" != ru ]] || continue
        [[ -z "${DiscoveredCodesSeen[$Code]+x}" ]] || continue
        DiscoveredCodesSeen["$Code"]=true
        Position="${#SortedCodes[@]}"
        while (( Position > 0 )) && [[ "$Code" < "${SortedCodes[Position - 1]}" ]]; do
            SortedCodes[Position]="${SortedCodes[Position - 1]}"
            ((Position--))
        done
        SortedCodes[Position]="$Code"
    done
    for Existing in "${SortedCodes[@]}"; do
        CodesOut+=("$Existing")
    done
    return 0
}

# Назначение: Проверяет код и строит принадлежащий каталогу программы путь внешнего языкового файла.
# shellcheck disable=SC2034  # PathOut is a nameref output.
external_language_file_path()
{
    local Language="$1"
    local -n PathOut="$2"
    local Directory="${RuntimeState[ProgramDirectory]}"
    local ExactPath="$Directory/$Language.lang"
    local CandidatePath=''
    local BaseName=''
    local Candidate=''
    local LC_ALL=C

    PathOut=''
    [[ "$Language" =~ ^[a-z]{2}$ && "$Language" != en && "$Language" != ru ]] || return 1
    if [[ -f "$ExactPath" && ! -L "$ExactPath" && -r "$ExactPath" ]]; then
        PathOut="$ExactPath"
        return 0
    fi
    for CandidatePath in "$Directory"/*; do
        [[ -f "$CandidatePath" && ! -L "$CandidatePath" && -r "$CandidatePath" ]] || continue
        BaseName="${CandidatePath##*/}"
        [[ "$BaseName" =~ ^([A-Za-z]{2})\.lang$ ]] || continue
        [[ "${BASH_REMATCH[1],,}" == "$Language" ]] || continue
        if [[ -z "$Candidate" || "$BaseName" < "${Candidate##*/}" ]]; then
            Candidate="$CandidatePath"
        fi
    done
    [[ -n "$Candidate" ]] || return 1
    PathOut="$Candidate"
    return 0
}

# Назначение: Формирует цикл выбора языка редактора из auto, встроенных и обнаруженных внешних каталогов без дублей.
# shellcheck disable=SC2034  # EditorLanguageCycleOut is a nameref output array.
build_editor_language_cycle()
{
    local -n EditorLanguageCycleOut="$1"
    local -a ExternalCodes=()

    EditorLanguageCycleOut=(auto ru en)
    discover_external_language_codes ExternalCodes || return $?
    EditorLanguageCycleOut+=("${ExternalCodes[@]}")
    return 0
}

# Назначение: Возвращает следующий код в цикле языка редактора с переходом от последнего к первому.
# shellcheck disable=SC2034  # NextLanguageOut is a nameref output.
next_editor_language_code()
{
    local CurrentLanguage="$1"
    local -n NextLanguageOut="$2"
    local NormalizedCurrent=''
    local Index=0
    local -a LanguageCycle=()

    build_editor_language_cycle LanguageCycle || return $?
    NextLanguageOut=auto
    normalize_language_identifier "$CurrentLanguage" NormalizedCurrent || return 12
    for ((Index=0; Index<${#LanguageCycle[@]}; Index++)); do
        if [[ "${LanguageCycle[Index]}" == "$NormalizedCurrent" ]]; then
            NextLanguageOut="${LanguageCycle[(Index + 1) % ${#LanguageCycle[@]}]}"
            break
        fi
    done
    return 0
}

# Назначение: Извлекает язык из текущей locale и сводит неподдерживаемые значения к английскому.
# shellcheck disable=SC2034  # LanguageOut is a nameref output.
resolve_locale_language()
{
    local -n LanguageOut="$1"
    local LocaleValue=''

    LanguageOut=en
    if [[ -n "${LC_ALL:-}" ]]; then
        LocaleValue="$LC_ALL"
    elif [[ -n "${LC_MESSAGES:-}" ]]; then
        LocaleValue="$LC_MESSAGES"
    else
        LocaleValue="${LANG:-}"
    fi
    case "${LocaleValue,,}" in
        c|c.*|posix|posix.*|'') return 0 ;;
    esac
    if [[ "$LocaleValue" =~ ^([A-Za-z]{2})([_-][A-Za-z]{2})?(\.[A-Za-z0-9][A-Za-z0-9._-]*)?(@[A-Za-z0-9][A-Za-z0-9._-]*)?$ ]]; then
        LanguageOut="${BASH_REMATCH[1],,}"
    fi
    return 0
}

# Назначение: Декодирует одно quoted-значение внешнего каталога без исполнения его как shell-кода.
# shellcheck disable=SC2034  # DecodedOut is a nameref output.
decode_language_value()
{
    local Encoded="$1"
    local -n DecodedOut="$2"
    local Index=0
    local Character=''
    local Escaped=''

    DecodedOut=''
    [[ -n "$Encoded" ]] || return 1
    for ((Index=0; Index<${#Encoded}; Index++)); do
        Character="${Encoded:Index:1}"
        [[ "$Character" != [$'\001'-$'\037'$'\177'] ]] || return 1
        if [[ "$Character" == \\ ]]; then
            ((Index++))
            (( Index < ${#Encoded} )) || return 1
            Escaped="${Encoded:Index:1}"
            case "$Escaped" in
                '"'|\\) DecodedOut+="$Escaped" ;;
                *) return 1 ;;
            esac
        elif [[ "$Character" == '"' ]]; then
            return 1
        else
            DecodedOut+="$Character"
        fi
    done
    [[ -n "$DecodedOut" ]]
}

# Назначение: Проверяет внешний lang-файл и накладывает только известные ключи поверх встроенного английского каталога.
# shellcheck disable=SC2034  # OverlayMessages is a catalog nameref output.
apply_external_language_overlay()
{
    local Language="$1"
    local CatalogName="${2:-PresentationMessages}"
    local -n OverlayMessages="$CatalogName"
    local Path=''
    local Content=''
    local Segment=''
    local Line=''
    local Key=''
    local Quoted=''
    local Inner=''
    local Decoded=''
    local BaseKey=''
    local FirstLine=true
    local ReadStatus=0
    local FileFd=0

    [[ "$Language" =~ ^[a-z]{2}$ ]] || return 80
    [[ "$Language" != en && "$Language" != ru ]] || return 0
    external_language_file_path "$Language" Path || return 0

    exec {FileFd}< "$Path" || return 0
    while true; do
        Segment=''
        IFS= read -r -d '' Segment <&$FileFd
        ReadStatus=$?
        Content+="$Segment"
        if (( ReadStatus == 0 )); then
            Content+=$'\001'
        else
            break
        fi
    done
    exec {FileFd}<&-

    while true; do
        Line=''
        IFS= read -r Line
        ReadStatus=$?
        if (( ReadStatus != 0 )) && [[ -z "$Line" ]]; then
            break
        fi
        if [[ "$FirstLine" == true ]]; then
            Line="${Line#$'\xEF\xBB\xBF'}"
            FirstLine=false
        fi
        Line="${Line%$'\r'}"
        if [[ -n "$Line" && "$Line" == *'='* &&
              "$Line" != *[$'\001'-$'\037'$'\177']* ]]; then
            Key="${Line%%=*}"
            Quoted="${Line#*=}"
            if [[ "$Quoted" == '"'*'"' && ${#Quoted} -ge 2 ]]; then
                Inner="${Quoted:1:${#Quoted}-2}"
                Decoded=''
                if decode_language_value "$Inner" Decoded; then
                    for BaseKey in "${!MessagesEn[@]}"; do
                        if [[ "$Key" == "msg_${BaseKey}_${Language}" ]]; then
                            OverlayMessages["$BaseKey"]="$Decoded"
                            break
                        fi
                    done
                fi
            fi
        fi
        (( ReadStatus == 0 )) || break
    done <<< "$Content"
    return 0
}

# Назначение: Создаёт итоговый каталог presentation для выбранного языка, включая fallback и внешний overlay.
# shellcheck disable=SC2034  # CatalogOut is a catalog nameref output.
build_localization_catalog()
{
    local RequestedLanguage="$1"
    local CatalogName="$2"
    local SelectedOutName="${3:-}"
    local -n CatalogOut="$CatalogName"
    local NormalizedLanguage=''
    local ResolvedLanguage=en
    local CatalogKey=''

    normalize_language_identifier "$RequestedLanguage" NormalizedLanguage || return 12
    if [[ "$NormalizedLanguage" == auto ]]; then
        resolve_locale_language ResolvedLanguage
    else
        ResolvedLanguage="$NormalizedLanguage"
    fi

    CatalogOut=()
    for CatalogKey in "${!MessagesEn[@]}"; do
        CatalogOut["$CatalogKey"]="${MessagesEn[$CatalogKey]}"
    done
    if [[ "$ResolvedLanguage" == ru ]]; then
        for CatalogKey in "${!MessagesRu[@]}"; do
            [[ -n "${MessagesEn[$CatalogKey]+x}" ]] || continue
            CatalogOut["$CatalogKey"]="${MessagesRu[$CatalogKey]}"
        done
    elif [[ "$ResolvedLanguage" != en ]]; then
        apply_external_language_overlay "$ResolvedLanguage" "$CatalogName" || return $?
    fi
    if [[ -n "$SelectedOutName" ]]; then
        local -n SelectedOut="$SelectedOutName"
        SelectedOut="$ResolvedLanguage"
    fi
    return 0
}

# Назначение: Строит временный каталог для предварительного показа языка без фиксации настройки запуска.
preview_presentation_language()
{
    local RequestedLanguage="$1"
    local SelectedLanguage=en
    local CatalogKey=''
    local -A PreviewCatalog=()

    build_localization_catalog "$RequestedLanguage" PreviewCatalog SelectedLanguage || return $?
    PresentationMessages=()
    for CatalogKey in "${!PreviewCatalog[@]}"; do
        PresentationMessages["$CatalogKey"]="${PreviewCatalog[$CatalogKey]}"
    done
    RuntimeState[PresentationLanguage]="$SelectedLanguage"
    return 0
}

# Назначение: Разрешает effective language/auto, строит каталог и сохраняет фактически выбранный язык runtime.
resolve_presentation_language()
{
    local RequestedLanguage=auto
    local SelectedLanguage=en
    local NormalizedLanguage=''

    if [[ "${CliState[LanguageProvided]:-false}" == true ]]; then
        normalize_language_identifier "${CliState[Language]:-}" NormalizedLanguage || return 12
        RequestedLanguage="$NormalizedLanguage"
        CliState[Language]="$NormalizedLanguage"
    elif [[ -n "${ParsedOptionConfig[Language]+x}" ]]; then
        RequestedLanguage="${ParsedOptionConfig[Language]}"
    else
        RequestedLanguage="${DefaultValues[Language]}"
    fi
    normalize_language_identifier "$RequestedLanguage" NormalizedLanguage || return 12
    build_localization_catalog "$NormalizedLanguage" PresentationMessages SelectedLanguage || return $?
    RuntimeState[PresentationLanguage]="$SelectedLanguage"
    return 0
}

# Назначение: Возвращает значение ключа из итогового каталога либо безопасный английский fallback.
# shellcheck disable=SC2034  # MessageOut is a nameref output.
localized_message()
{
    local Key="$1"
    local -n MessageOut="$2"

    if [[ -n "${PresentationMessages[$Key]+x}" ]]; then
        MessageOut="${PresentationMessages[$Key]}"
    elif [[ "${EffectiveConfig[Language]:-}" == ru &&
            -n "${MessagesRu[$Key]+x}" ]]; then
        MessageOut="${MessagesRu[$Key]}"
    else
        MessageOut="${MessagesEn[$Key]:-$Key}"
    fi
    return 0
}

# Назначение: Сопоставляет имя конфигурационного поля ключу его локализованного подробного описания.
# shellcheck disable=SC2034  # MessageKeyOut is a nameref output.
field_description_message_key()
{
    local CanonicalKey="$1"
    local -n MessageKeyOut="$2"

    case "$CanonicalKey" in
        Language) MessageKeyOut=description_language ;;
        UseOxidized) MessageKeyOut=description_use_oxidized ;;
        OxidizedHome) MessageKeyOut=description_oxidized_home ;;
        UseIdentityName) MessageKeyOut=description_use_identity_name ;;
        backup_type) MessageKeyOut=description_backup_type ;;
        UseIncremental) MessageKeyOut=description_use_incremental ;;
        export_format) MessageKeyOut=description_export_format ;;
        show_sensitive) MessageKeyOut=description_show_sensitive ;;
        encrypt) MessageKeyOut=description_encrypt ;;
        clear_dns_cache) MessageKeyOut=description_clear_dns_cache ;;
        clear_console_history) MessageKeyOut=description_clear_console_history ;;
        BackupRoot) MessageKeyOut=description_backup_root ;;
        UseNetFolder) MessageKeyOut=description_use_net_folder ;;
        MonthlyArchive) MessageKeyOut=description_monthly_archive ;;
        LogLevel) MessageKeyOut=description_log_level ;;
        MainLogPath) MessageKeyOut=description_main_log_path ;;
        Save) MessageKeyOut=description_save ;;
        Cancel) MessageKeyOut=description_cancel ;;
        *) return 80 ;;
    esac
    return 0
}

# Назначение: Возвращает описание поля через canonical mapping, сохраняя общий fallback для неизвестного ключа.
# shellcheck disable=SC2034  # DescriptionOut is a nameref output.
localized_field_description()
{
    local CanonicalKey="$1"
    local -n DescriptionOut="$2"
    local MessageKey=''

    field_description_message_key "$CanonicalKey" MessageKey || return $?
    localized_message "$MessageKey" DescriptionOut
}

# Назначение: Возвращает пользовательскую подпись конфигурационного поля для форм и сводок.
# shellcheck disable=SC2034  # LabelOut is a nameref output.
localized_field_label()
{
    local Field="$1"
    local -n LabelOut="$2"
    local MessageKey=''

    case "$Field" in
        Language) MessageKey=field_language ;;
        SshPort) MessageKey=field_ssh_port ;;
        UseOxidized) MessageKey=field_use_oxidized ;;
        IgnoreOxiAccess) MessageKey=field_ignore_oxi_access ;;
        OxidizedHome) MessageKey=field_oxidized_home ;;
        UseIdentityName) MessageKey=field_use_identity_name ;;
        BackupRoot) MessageKey=field_backup_root ;;
        UseNetFolder) MessageKey=field_use_net_folder ;;
        MonthlyArchive) MessageKey=field_monthly_archive ;;
        LogLevel) MessageKey=field_log_level ;;
        MainLogPath) MessageKey=field_main_log_path ;;
        Address) MessageKey=field_address ;;
        User) MessageKey=field_user ;;
        Password) MessageKey=field_password ;;
        DeviceName) MessageKey=field_device_name ;;
        backup_type) MessageKey=field_backup_type ;;
        UseIncremental) MessageKey=field_use_incremental ;;
        export_format) MessageKey=field_export_format ;;
        show_sensitive) MessageKey=field_show_sensitive ;;
        encrypt) MessageKey=field_encrypt ;;
        clear_dns_cache) MessageKey=field_clear_dns_cache ;;
        clear_console_history) MessageKey=field_clear_console_history ;;
        *) return 80 ;;
    esac
    localized_message "$MessageKey" LabelOut
}

# Назначение: Удаляет управляющие ANSI-последовательности из текста перед измерением или нецветным выводом.
# shellcheck disable=SC2034  # PlainTextOut is a nameref output.
ui_strip_ansi()
{
    local AnsiInput="$1"
    local -n PlainTextOut="$2"
    local EscapePattern=$'\033''\[[0-9;]*[[:alpha:]]'

    while [[ "$AnsiInput" =~ $EscapePattern ]]; do
        AnsiInput="${AnsiInput/"${BASH_REMATCH[0]}"/}"
    done
    PlainTextOut="$AnsiInput"
    return 0
}

# Назначение: Форматирует effective-значение для UI: локализует boolean, маскирует секреты и показывает пустое значение явно.
# shellcheck disable=SC2034  # DisplayOut is a nameref output.
localized_config_display_value()
{
    local Field="$1"
    local RawValue="$2"
    local -n DisplayOut="$3"
    local Key=''

    case "$Field" in
        MonthlyArchive)
            if [[ "$RawValue" == false ]]; then
                localized_message no DisplayOut
            else
                DisplayOut="$RawValue"
            fi
            ;;
        UseOxidized|UseIdentityName|UseNetFolder|UseIncremental|show_sensitive|clear_dns_cache|clear_console_history)
            if [[ "$RawValue" == true ]]; then Key=yes; else Key=no; fi
            localized_message "$Key" DisplayOut
            ;;
        backup_type)
            localized_message "value_${RawValue}" DisplayOut
            ;;
        export_format)
            localized_message "value_${RawValue}" DisplayOut
            ;;
        encrypt)
            if [[ -z "$RawValue" ]]; then
                localized_message no DisplayOut
            else
                printf -v DisplayOut '%*s' "${#RawValue}" ''
                DisplayOut="${DisplayOut// /*}"
            fi
            ;;
        *) DisplayOut="$RawValue" ;;
    esac
    return 0
}

# Назначение: Печатает локализованное сообщение в stdout либо stderr, не смешивая выбор текста с бизнес-логикой.
emit_message()
{
    local Key="$1"
    local Message

    localized_message "$Key" Message
    printf '%s\n' "$Message" >&2
    return 0
}

# ==============================================================================
# CLI parsing, diagnostics and execution intent
# ==============================================================================

# Назначение: Учитывает выбранное CLI-действие и число его появлений для последующей проверки конфликтов.
record_cli_action()
{
    local Action="$1"
    CliActions["$Action"]=1
    return 0
}

# Назначение: Разбирает поддержанные длинные/короткие аргументы в CliState, не исполняя выбранное действие.
parse_cli()
{
    local Token
    local Key=''
    local Value=''
    local ParseStatus=0

    CliState=()
    CliActions=()
    CliState[AddressProvided]=false
    CliState[UserProvided]=false
    CliState[PasswordProvided]=false

    while (($# > 0)); do
        Token="$1"
        Key=''
        Value=''
        case "$Token" in
            -i) record_cli_action menu ;;
            -b) record_cli_action wizard ;;
            -e) record_cli_action editor ;;
            -r) record_cli_action restore ;;
            -o) record_cli_action auxiliary ;;
            -h|--help) record_cli_action help ;;
            -v|--version) record_cli_action version ;;
            -a=*) Key=address; Value="${Token#*=}" ;;
            -u=*) Key=user; Value="${Token#*=}" ;;
            -p=*) Key=password; Value="${Token#*=}" ;;
            --device-name=*|--address=*|--user=*|--password=*|--port=*|--language=*|--use-oxidized=*|--oxidized-home=*|--use-identity-name=*|--backup-root=*|--use-net-folder=*|--monthly-archive=*|--log-level=*|--main-log-path=*|--backup-type=*|--export-format=*|--show-sensitive=*|--encrypt=*|--clear-dns-cache=*|--clear-console-history=*)
                Key="${Token%%=*}"
                Key="${Key#--}"
                Value="${Token#*=}"
                ;;
            --device-name|--address|--user|--password|--port|--language|--use-oxidized|--oxidized-home|--use-identity-name|--backup-root|--use-net-folder|--monthly-archive|--log-level|--main-log-path|--backup-type|--export-format|--show-sensitive|--encrypt|--clear-dns-cache|--clear-console-history)
                Key="${Token#--}"
                if (($# > 1)) && [[ "$2" != -* ]]; then
                    Value="$2"
                    shift
                else
                    ParseStatus=12
                fi
                ;;
            *) ParseStatus=12 ;;
        esac
        if [[ -n "$Key" ]]; then
            case "$Key" in
                device-name) CliState[DeviceName]="$Value"; CliState[DeviceNameProvided]=true ;;
                address) CliState[Address]="$Value"; CliState[AddressProvided]=true ;;
                user) CliState[User]="$Value"; CliState[UserProvided]=true ;;
                password) CliState[Password]="$Value"; CliState[PasswordProvided]=true ;;
                port) CliState[SshPort]="$Value"; CliState[SshPortProvided]=true ;;
                language) CliState[Language]="$Value"; CliState[LanguageProvided]=true ;;
                use-oxidized) CliState[UseOxidized]="$Value"; CliState[UseOxidizedProvided]=true ;;
                oxidized-home) CliState[OxidizedHome]="$Value"; CliState[OxidizedHomeProvided]=true ;;
                use-identity-name) CliState[UseIdentityName]="$Value"; CliState[UseIdentityNameProvided]=true ;;
                backup-root) CliState[BackupRoot]="$Value"; CliState[BackupRootProvided]=true ;;
                use-net-folder) CliState[UseNetFolder]="$Value"; CliState[UseNetFolderProvided]=true ;;
                monthly-archive) CliState[MonthlyArchive]="$Value"; CliState[MonthlyArchiveProvided]=true ;;
                log-level) CliState[LogLevel]="$Value"; CliState[LogLevelProvided]=true ;;
                main-log-path) CliState[MainLogPath]="$Value"; CliState[MainLogPathProvided]=true ;;
                backup-type) CliState[backup_type]="$Value"; CliState[backup_typeProvided]=true ;;
                export-format) CliState[export_format]="$Value"; CliState[export_formatProvided]=true ;;
                show-sensitive) CliState[show_sensitive]="$Value"; CliState[show_sensitiveProvided]=true ;;
                encrypt) CliState[encrypt]="$Value"; CliState[encryptProvided]=true ;;
                clear-dns-cache) CliState[clear_dns_cache]="$Value"; CliState[clear_dns_cacheProvided]=true ;;
                clear-console-history) CliState[clear_console_history]="$Value"; CliState[clear_console_historyProvided]=true ;;
            esac
        fi
        shift
    done
    (( ParseStatus == 0 )) || return 12
    validate_cli_values
}

# Назначение: Проверяет значения разобранных опций и нормализует те, для которых контракт задаёт aliases.
validate_cli_values()
{
    local Field=''
    local Value=''
    local Validated=''

    for Field in DeviceName Address User Password; do
        if [[ "${CliState[${Field}Provided]:-false}" == true &&
              -z "${CliState[$Field]:-}" ]]; then
            return 12
        fi
    done
    for Field in Language SshPort UseOxidized OxidizedHome UseIdentityName BackupRoot UseNetFolder MonthlyArchive LogLevel MainLogPath backup_type export_format show_sensitive clear_dns_cache clear_console_history; do
        [[ "${CliState[${Field}Provided]:-false}" == true ]] || continue
        Value="${CliState[$Field]:-}"
        [[ -n "$Value" ]] || return 12
        Validated=''
        validate_ordinary_config_value "$Field" "$Value" Validated || return 12
        CliState["$Field"]="$Validated"
    done
    if [[ "${CliState[encryptProvided]:-false}" == true &&
          -z "${CliState[encrypt]:-}" ]]; then
        return 12
    fi
    return 0
}

# Назначение: Отклоняет несовместимые или повторённые действия командной строки.
validate_action_selection()
{
    if (( ${#CliActions[@]} > 1 )); then
        return 12
    fi
    return 0
}

# Назначение: Считает заполненные address/user/password, чтобы отличить полный single-набор от частичного.
count_single_fields()
{
    local -n CountOut="$1"
    CountOut=0

    [[ "${CliState[AddressProvided]:-false}" == true ]] && ((CountOut++))
    [[ "${CliState[UserProvided]:-false}" == true ]] && ((CountOut++))
    [[ "${CliState[PasswordProvided]:-false}" == true ]] && ((CountOut++))
    return 0
}

# Назначение: Выводит единственный режим запуска из CLI-действий и наличия полного набора реквизитов.
determine_execution_intent()
{
    local Action=''
    local FieldCount=0

    ExecutionIntent=()
    count_single_fields FieldCount
    ExecutionIntent[SingleFieldCount]="$FieldCount"

    if (( ${#CliActions[@]} == 1 )); then
        for Action in "${!CliActions[@]}"; do
            :
        done
        if [[ "$Action" == menu ]]; then
            case "$FieldCount" in
                3) ExecutionIntent[Kind]=single; return 0 ;;
                1|2) ExecutionIntent[Kind]=partial_single; return 0 ;;
            esac
        fi
        case "$Action" in
            menu) ExecutionIntent[Kind]=menu ;;
            wizard) ExecutionIntent[Kind]=wizard ;;
            *) ExecutionIntent[Kind]=terminal_action; ExecutionIntent[Action]="$Action" ;;
        esac
        return 0
    fi

    case "$FieldCount" in
        0) ExecutionIntent[Kind]=batch_candidate ;;
        3) ExecutionIntent[Kind]=single ;;
        *) ExecutionIntent[Kind]=partial_single ;;
    esac
    return 0
}

# Назначение: Печатает точную диагностику недостающих полей неполного single-запроса.
emit_partial_single_diagnostic()
{
    local Field
    local FieldLabel=''
    local MissingFields=''
    local Message

    for Field in Address User Password; do
        if [[ "${CliState[${Field}Provided]:-false}" != true ]]; then
            localized_field_label "$Field" FieldLabel || return $?
            MissingFields+="${MissingFields:+, }$FieldLabel"
        fi
    done
    localized_message partial_single Message
    printf '%s %s\n' "$Message" "$MissingFields" >&2
    return 0
}

# ==============================================================================
# Defaults, option.cfg and effective/staged configuration policy
# ==============================================================================

# Назначение: Задаёт канонические defaults конфигурации, включая выключенный MonthlyArchive.
init_default_values()
{
    DefaultValues=()
    DefaultValues[Language]=auto
    DefaultValues[SshPort]=22
    DefaultValues[UseOxidized]=false
    DefaultValues[IgnoreOxiAccess]=true
    DefaultValues[OxidizedHome]=''
    DefaultValues[UseIdentityName]=true
    DefaultValues[BackupRoot]=backups
    DefaultValues[UseNetFolder]=false
    DefaultValues[MonthlyArchive]=false
    DefaultValues[LogLevel]=2
    DefaultValues[MainLogPath]=''
    DefaultValues[backup_type]=both
    DefaultValues[UseIncremental]=true
    DefaultValues[export_format]=compact
    DefaultValues[show_sensitive]=true
    DefaultValues[encrypt]=''
    DefaultValues[encrypt_type]=aes-sha256
    DefaultValues[clear_dns_cache]=true
    DefaultValues[clear_console_history]=true
    DefaultValues[Login]=''
    DefaultValues[Password]=''
    return 0
}

# Назначение: Удаляет только внешние пробельные символы из недоверенного текстового значения через nameref.
# shellcheck disable=SC2034  # TrimmedOut is a nameref output.
trim_external_whitespace()
{
    local Value="$1"
    local -n TrimmedOut="$2"

    Value="${Value#"${Value%%[![:space:]]*}"}"
    Value="${Value%"${Value##*[![:space:]]}"}"
    TrimmedOut="$Value"
    return 0
}

# Назначение: Преобразует прежние boolean aliases в строгое true/false, не принимая числовые дни.
# shellcheck disable=SC2034  # NormalizedOut is a nameref output.
normalize_boolean()
{
    local Value="${1,,}"
    local -n NormalizedOut="$2"

    case "$Value" in
        true|yes|1|on) NormalizedOut=true; return 0 ;;
        false|no|0|off) NormalizedOut=false; return 0 ;;
        *) return 21 ;;
    esac
}

# Назначение: Нормализует MonthlyArchive в false либо день 1..28, сохраняя совместимые boolean aliases.
# shellcheck disable=SC2034  # NormalizedOut is a nameref output.
normalize_monthly_archive()
{
    local Value="${1,,}"
    local -n NormalizedOut="$2"

    case "$Value" in
        false|no|0|off) NormalizedOut=false; return 0 ;;
        true|yes|1|on) NormalizedOut=1; return 0 ;;
        [2-9]|1[0-9]|2[0-8]) NormalizedOut="$Value"; return 0 ;;
        *) return 21 ;;
    esac
}

# Назначение: Проверяет одно поле конфигурации по его собственному типу и ограничениям, не расширяя остальные boolean-поля.
# shellcheck disable=SC2034  # ValidatedOut is a nameref output.
validate_ordinary_config_value()
{
    local Key="$1"
    local InputValue="$2"
    local -n ValidatedOut="$3"
    local BooleanValue

    case "$Key" in
        Language)
            normalize_language_identifier "$InputValue" ValidatedOut && return 0
            ;;
        SshPort)
            if [[ "$InputValue" =~ ^[0-9]+$ ]] &&
               ((10#$InputValue >= 1 && 10#$InputValue <= 65535)); then
                ValidatedOut="$((10#$InputValue))"
                return 0
            fi
            ;;
        LogLevel)
            if [[ "$InputValue" =~ ^[0-3]$ ]]; then
                ValidatedOut="$InputValue"
                return 0
            fi
            ;;
        MonthlyArchive)
            if normalize_monthly_archive "$InputValue" BooleanValue; then
                ValidatedOut="$BooleanValue"
                return 0
            fi
            ;;
        UseOxidized|IgnoreOxiAccess|UseIdentityName|UseNetFolder|UseIncremental|show_sensitive|clear_dns_cache|clear_console_history)
            if normalize_boolean "$InputValue" BooleanValue; then
                ValidatedOut="$BooleanValue"
                return 0
            fi
            ;;
        OxidizedHome)
            ValidatedOut="$InputValue"
            return 0
            ;;
        BackupRoot)
            if [[ -n "$InputValue" ]]; then
                ValidatedOut="$InputValue"
                return 0
            fi
            ;;
        MainLogPath)
            ValidatedOut="$InputValue"
            return 0
            ;;
        backup_type)
            case "${InputValue,,}" in
                configuration|config|conf) ValidatedOut=configuration; return 0 ;;
                binary|both) ValidatedOut="${InputValue,,}"; return 0 ;;
            esac
            ;;
        export_format)
            case "${InputValue,,}" in
                compact|terse|verbose) ValidatedOut="${InputValue,,}"; return 0 ;;
            esac
            ;;
        encrypt)
            ValidatedOut="$InputValue"
            return 0
            ;;
        encrypt_type)
            if [[ "${InputValue,,}" == aes-sha256 ]]; then
                ValidatedOut=aes-sha256
                return 0
            fi
            ;;
    esac
    return 21
}

# Назначение: Читает числовые permission bits существующего объекта переносимым вызовом stat.
# shellcheck disable=SC2034  # BitsOut is a nameref output.
file_permission_bits()
{
    local Path="$1"
    local -n BitsOut="$2"
    local Mode
    local -a StatCommand=(stat -Lc '%a' -- "$Path")

    Mode="$("${StatCommand[@]}" 2>/dev/null)" || return 21
    [[ "$Mode" =~ ^[0-7]+$ ]] || return 21
    BitsOut=$((8#$Mode))
    return 0
}

# Назначение: Допускает чтение конфигурации только из regular-файла текущего пользователя с безопасным режимом.
trusted_input_configuration_object()
{
    local Path="$1"

    [[ -f "$Path" && -r "$Path" ]]
}

# Назначение: Разбирает option.cfg как данные: проверяет синтаксис, ключи, дубли и значения без source/eval.
# shellcheck disable=SC2034  # SeenOut is an optional nameref output.
parse_option_config()
{
    local Path="$1"
    local -n ConfigOut="$2"
    local SeenOutName="${3:-}"
    local Line=''
    local Key=''
    local Value=''
    local TrimmedKey=''
    local TrimmedValue=''
    local CanonicalKey=''
    local ValidatedValue=''
    local FirstLine=true
    local ReadStatus=0
    local -A SeenKeys=()

    if [[ -n "$SeenOutName" ]]; then
        local -n SeenOut="$SeenOutName"
        SeenOut=()
    fi

    [[ -e "$Path" || -L "$Path" ]] || return 0
    trusted_input_configuration_object "$Path" || return 21

    Line=''
    while true; do
        IFS= read -r Line
        ReadStatus=$?
        if (( ReadStatus != 0 )) && [[ -z "$Line" ]]; then
            break
        fi

        if [[ "$FirstLine" == true ]]; then
            Line="${Line#$'\xEF\xBB\xBF'}"
            FirstLine=false
        fi
        Line="${Line%$'\r'}"

        trim_external_whitespace "$Line" TrimmedValue
        if [[ -z "$TrimmedValue" || "${TrimmedValue:0:1}" == '#' ]]; then
            (( ReadStatus == 0 )) || break
            continue
        fi
        if [[ "$Line" != *'='* ]]; then
            (( ReadStatus == 0 )) || break
            continue
        fi

        Key="${Line%%=*}"
        Value="${Line#*=}"
        trim_external_whitespace "$Key" TrimmedKey
        if [[ -z "$TrimmedKey" ]]; then
            (( ReadStatus == 0 )) || break
            continue
        fi
        case "${TrimmedKey,,}" in
            language) CanonicalKey=Language ;;
            sshport) CanonicalKey=SshPort ;;
            useoxidized) CanonicalKey=UseOxidized ;;
            ignoreoxiaccess) CanonicalKey=IgnoreOxiAccess ;;
            oxidizedhome) CanonicalKey=OxidizedHome ;;
            useidentityname) CanonicalKey=UseIdentityName ;;
            backuproot) CanonicalKey=BackupRoot ;;
            usenetfolder) CanonicalKey=UseNetFolder ;;
            monthlyarchive) CanonicalKey=MonthlyArchive ;;
            loglevel) CanonicalKey=LogLevel ;;
            mainlogpath) CanonicalKey=MainLogPath ;;
            backup_type) CanonicalKey=backup_type ;;
            useincremental) CanonicalKey=UseIncremental ;;
            export_format) CanonicalKey=export_format ;;
            show_sensitive) CanonicalKey=show_sensitive ;;
            encrypt) CanonicalKey=encrypt ;;
            encrypt_type) CanonicalKey=encrypt_type ;;
            clear_dns_cache) CanonicalKey=clear_dns_cache ;;
            clear_console_history) CanonicalKey=clear_console_history ;;
            login) CanonicalKey=Login ;;
            password) CanonicalKey=Password ;;
            *)
                (( ReadStatus == 0 )) || break
                continue
                ;;
        esac

        if [[ "$CanonicalKey" == Login || "$CanonicalKey" == Password ||
              "$CanonicalKey" == encrypt ]]; then
            ValidatedValue="$Value"
        else
            trim_external_whitespace "$Value" TrimmedValue
            ValidatedValue=''
            if validate_ordinary_config_value "$CanonicalKey" "$TrimmedValue" ValidatedValue; then
                :
            else
                (( ReadStatus == 0 )) || break
                continue
            fi
        fi
        SeenKeys["$CanonicalKey"]=1
        ConfigOut["$CanonicalKey"]="$ValidatedValue"
        if [[ -n "$SeenOutName" ]]; then
            SeenOut["$CanonicalKey"]=1
        fi
        (( ReadStatus == 0 )) || break
    done < "$Path"

    return 0
}

# Назначение: Загружает доверенный option.cfg либо сохраняет defaults и диагностическое состояние причины отказа.
load_startup_option_config()
{
    local Key=''

    ParsedOptionConfig=()
    ParsedOptionSeen=()
    for Key in "${!DefaultValues[@]}"; do
        ParsedOptionConfig["$Key"]="${DefaultValues[$Key]}"
    done
    RuntimeState[StartupConfigExists]=false
    RuntimeState[StartupConfigUsable]=false
    if [[ -e "${RuntimeState[OptionConfigPath]}" ||
          -L "${RuntimeState[OptionConfigPath]}" ]]; then
        RuntimeState[StartupConfigExists]=true
        parse_option_config "${RuntimeState[OptionConfigPath]}" \
            ParsedOptionConfig ParsedOptionSeen || return 21
    fi
    if (( ${#ParsedOptionSeen[@]} > 0 )); then
        RuntimeState[StartupConfigUsable]=true
    fi
    RuntimeState[StartupConfigLoaded]=true
    RuntimeState[StartupConfigReadCount]=1
    return 0
}

# Назначение: Создаёт полный EffectiveConfig как независимую копию канонических defaults.
copy_defaults_to_effective_config()
{
    local Key
    EffectiveConfig=()
    for Key in "${!DefaultValues[@]}"; do
        EffectiveConfig["$Key"]="${DefaultValues[$Key]}"
    done
    return 0
}

# Назначение: Накладывает явно заданные CLI-значения поверх текущей effective-конфигурации.
apply_cli_to_effective_config()
{
    local Key

    for Key in Language SshPort UseOxidized OxidizedHome UseIdentityName BackupRoot UseNetFolder MonthlyArchive LogLevel MainLogPath backup_type export_format show_sensitive encrypt clear_dns_cache clear_console_history; do
        if [[ "${CliState[${Key}Provided]:-false}" == true ]]; then
            EffectiveConfig["$Key"]="${CliState[$Key]}"
        fi
    done
    if [[ "${CliState[AddressProvided]:-false}" == true ]]; then
        EffectiveConfig[Address]="${CliState[Address]}"
    fi
    if [[ "${CliState[DeviceNameProvided]:-false}" == true ]]; then
        EffectiveConfig[DeviceName]="${CliState[DeviceName]}"
    fi
    if [[ "${CliState[UserProvided]:-false}" == true ]]; then
        EffectiveConfig[User]="${CliState[User]}"
    fi
    if [[ "${CliState[PasswordProvided]:-false}" == true ]]; then
        EffectiveConfig[DevicePassword]="${CliState[Password]}"
    fi
    return 0
}

# Назначение: Собирает effective-конфигурацию в порядке defaults → startup file → CLI.
construct_effective_config()
{
    local Kind="${ExecutionIntent[Kind]}"
    local Key

    copy_defaults_to_effective_config
    case "$Kind" in
        batch_candidate|single|wizard|menu)
            if [[ "${RuntimeState[StartupConfigLoaded]:-false}" == true ]]; then
                for Key in "${!ParsedOptionConfig[@]}"; do
                    EffectiveConfig["$Key"]="${ParsedOptionConfig[$Key]}"
                done
            else
                parse_option_config "${RuntimeState[OptionConfigPath]}" EffectiveConfig || return $?
            fi
            apply_cli_to_effective_config
            ;;
    esac
    return 0
}

# Назначение: Повторно проверяет каждое итоговое поле после всех слоёв и контекстных преобразований.
validate_effective_config()
{
    local Validated=''
    local Key

    LoggingState[ConfigurationResolved]=false
    for Key in Language SshPort UseOxidized IgnoreOxiAccess OxidizedHome UseIdentityName backup_type UseIncremental export_format show_sensitive encrypt encrypt_type clear_dns_cache clear_console_history BackupRoot UseNetFolder MonthlyArchive LogLevel MainLogPath; do
        Validated=''
        if ! validate_ordinary_config_value "$Key" "${EffectiveConfig[$Key]}" Validated; then
            return 12
        fi
        EffectiveConfig["$Key"]="$Validated"
    done

    if [[ -n "${EffectiveConfig[MainLogPath]}" &&
          "${EffectiveConfig[MainLogPath]}" != /* ]]; then
        EffectiveConfig[MainLogPath]="${RuntimeState[ProgramDirectory]}/${EffectiveConfig[MainLogPath]}"
    fi
    if [[ "${ExecutionIntent[Kind]}" == single ]]; then
        [[ -n "${EffectiveConfig[Address]:-}" ]] || return 12
        [[ -n "${EffectiveConfig[User]:-}" ]] || return 12
        [[ -n "${EffectiveConfig[DevicePassword]:-}" ]] || return 12
    fi
    # shellcheck disable=SC2034  # Buffered event flushing begins in TASK-023.
    LoggingState[ConfigurationResolved]=true
    return 0
}

# Назначение: Сбрасывает зависящие поля, когда родительский переключатель делает их неприменимыми.
# shellcheck disable=SC2154  # ShellCheck cannot resolve associative keys through this configuration nameref.
apply_config_context_resets()
{
    local ConfigName="$1"
    local ChangedField="$2"
    local -n ContextConfig="$ConfigName"

    if [[ "$ChangedField" == UseOxidized && "${ContextConfig[UseOxidized]}" != true ]]; then
        ContextConfig[OxidizedHome]="${DefaultValues[OxidizedHome]}"
    fi
    if [[ "$ChangedField" == backup_type ]]; then
        case "${ContextConfig[backup_type]}" in
            configuration)
                ContextConfig[encrypt]="${DefaultValues[encrypt]}"
                ContextConfig[clear_dns_cache]="${DefaultValues[clear_dns_cache]}"
                ContextConfig[clear_console_history]="${DefaultValues[clear_console_history]}"
                ;;
            binary)
                ContextConfig[export_format]="${DefaultValues[export_format]}"
                ContextConfig[show_sensitive]="${DefaultValues[show_sensitive]}"
                ;;
        esac
    fi
    return 0
}

# Назначение: Фиксирует batch или single в ExecutionState согласно ранее проверенному execution intent.
resolve_run_mode()
{
    : "${1:-}"

    ExecutionState=()
    case "${ExecutionIntent[Kind]}" in
        single) ExecutionState[RunMode]=single; return 0 ;;
        menu) ExecutionState[RunMode]=menu; return 0 ;;
        wizard) ExecutionState[RunMode]=wizard; return 0 ;;
        batch_candidate)
            ExecutionState[RunMode]='batch'
            ExecutionState[DeviceListEligibleForRun]=true
            if [[ "${EffectiveConfig[UseOxidized]}" == true ]]; then
                ExecutionState[OxidizedConfigPath]="${EffectiveConfig[OxidizedHome]%/}/config"
                ExecutionState[OxidizedRouterDbPath]="${EffectiveConfig[OxidizedHome]%/}/router.db"
                ExecutionState[DeviceSourceType]=oxidized
            else
                ExecutionState[DeviceSourcePath]="${RuntimeState[DeviceListPath]}"
                ExecutionState[DeviceSourceType]=canonical_tsv
            fi
            return 0
            ;;
    esac
    return 80
}

# ==============================================================================
# Shared filesystem creation primitive and atomic control-file publication
# ==============================================================================

# Назначение: Канонизирует каталог и целевой путь служебного файла перед атомарной публикацией.
# shellcheck disable=SC2034  # ResolvedOut is a nameref output.
resolve_control_file_publication_path()
{
    local RequestedPath="$1"
    local -n ResolvedOut="$2"
    local -a RealpathCommand=(realpath -m -- "$RequestedPath")

    if [[ -L "$RequestedPath" ]]; then
        ResolvedOut="$("${RealpathCommand[@]}" 2>/dev/null)" || return 35
        [[ -n "$ResolvedOut" ]] || return 35
    else
        ResolvedOut="$RequestedPath"
    fi
    return 0
}

# Назначение: Выполняет одну noclobber-попытку перенаправления по переданному пути; статус 0 не доказывает тип файла или владение им, открытый дескриптор вызывающему коду не передаётся.
# A zero status proves only that Bash accepted the noclobber redirection.
# Callers must establish regular-file identity and ownership before trust or unlink.
attempt_noclobber_redirection()
{
    local Path="$1"

    (set -o noclobber; : > "$Path") 2>/dev/null
}

# Назначение: Создаёт, регистрирует и подтверждает владение приватным временным файлом рядом с целью публикации.
# shellcheck disable=SC2034  # PathOut and CleanupEntryIdOut are nameref outputs.
create_atomic_temp_file()
{
    local Directory="$1"
    local BaseName="$2"
    local -n PathOut="$3"
    local -n CleanupEntryIdOut="$4"
    local Attempt
    local Candidate
    local CandidateDevice=''
    local CandidateInode=''
    local NewCleanupEntryId=''

    PathOut=''
    CleanupEntryIdOut=''
    for ((Attempt=0; Attempt<100; Attempt++)); do
        Candidate="$Directory/.${BaseName}.tmp.$$.$RANDOM.$Attempt"
        if attempt_noclobber_redirection "$Candidate"; then
            # Observation failure exposes no identity proof; preserve the current pathname.
            cleanup_path_identity "$Candidate" CandidateDevice CandidateInode || return 21
            # Failed exact registration leaves the pathname unproved to its caller.
            register_cleanup_entry \
                file "$Candidate" true "$CandidateDevice" "$CandidateInode" \
                NewCleanupEntryId || return 21
            PathOut="$Candidate"
            CleanupEntryIdOut="$NewCleanupEntryId"
            return 0
        fi
    done
    return 21
}

# Назначение: Безопасно удаляет принадлежащий временный файл и снимает его cleanup-регистрацию.
discard_atomic_temp_file()
{
    local Path="$1"
    local EntryId="$2"
    local Declaration=''
    local MatchStatus=0
    local RemoveStatus=0
    local -a RemoveCommand=(rm -f -- "$Path")

    [[ "$EntryId" =~ ^CleanupEntry_[0-9]+$ ]] || return 0
    Declaration="$(declare -p "$EntryId" 2>/dev/null)" || return 0
    [[ "$Declaration" == "declare -A $EntryId="* ]] || return 0
    local -n AtomicTempEntry="$EntryId"
    [[ "${AtomicTempEntry[Active]:-false}" == true &&
       "${AtomicTempEntry[Owned]:-false}" == true &&
       "${AtomicTempEntry[Type]:-}" == file &&
       "${AtomicTempEntry[Value]:-}" == "$Path" ]] || return 0

    cleanup_entry_matches_path "$EntryId" || MatchStatus=$?
    if (( MatchStatus != 0 )); then
        unregister_cleanup_entry "$EntryId" || :
        return 0
    fi

    "${RemoveCommand[@]}" || RemoveStatus=$?
    if (( RemoveStatus != 0 )); then
        return 0
    fi
    unregister_cleanup_entry "$EntryId" || :
    return 0
}

# Назначение: Сопоставляет ключ option.cfg локализованному комментарию канонического writer.
# shellcheck disable=SC2034  # MessageKeyOut is a nameref output.
option_comment_message_key()
{
    local CanonicalKey="$1"
    local -n MessageKeyOut="$2"

    case "$CanonicalKey" in
        SshPort) MessageKeyOut=comment_ssh_port ;;
        IgnoreOxiAccess) MessageKeyOut=comment_ignore_oxi_access ;;
        encrypt_type) MessageKeyOut=comment_encrypt_type ;;
        Login) MessageKeyOut=comment_login ;;
        Password) MessageKeyOut=comment_password ;;
        *) field_description_message_key "$CanonicalKey" "$2" ;;
    esac
}

# Назначение: Разбивает локализованное описание настройки на строки комментария заданной ширины.
emit_option_comment()
{
    local Comment="$1"
    local PlainComment=''
    local PhysicalLine=''

    ui_strip_ansi "$Comment" PlainComment
    PlainComment="${PlainComment//$'\033'/}"
    while IFS= read -r PhysicalLine || [[ -n "$PhysicalLine" ]]; do
        printf '# %s\n' "$PhysicalLine"
    done <<< "$PlainComment"
    return 0
}

# Назначение: Записывает одну настройку option.cfg с описанием и безопасным shell-quoted значением.
write_canonical_option_setting()
{
    local CatalogName="$1"
    local CanonicalKey="$2"
    local CanonicalValue="$3"
    local -n CommentCatalog="$CatalogName"
    local MessageKey=''
    local Comment=''

    option_comment_message_key "$CanonicalKey" MessageKey || return 80
    Comment="${CommentCatalog[$MessageKey]:-${MessagesEn[$MessageKey]:-$MessageKey}}"
    emit_option_comment "$Comment" || return $?
    printf '%s=%s\n' "$CanonicalKey" "$CanonicalValue"
    return 0
}

# Назначение: Публикует полный option.cfg через приватный staging-файл и атомарную замену точной цели.
write_canonical_option_config()
{
    local Path="$1"
    local -n ConfigIn="$2"
    local PublishPath=''
    local Directory
    local BaseName
    local TempPath=''
    local TempCleanupId=''
    local WriteStatus=0
    local -A ExistingConfig=()
    local -A ExistingSeen=()
    local -A ValidationConfig=()
    local ExistingLoginPresent=false
    local ExistingPasswordPresent=false
    local CanonicalValue
    local ConfigKey
    local -A CanonicalConfig=()
    local ProductHeader=''
    local PassportFile=''
    local PassportPurpose=''
    # Consumed dynamically through canonical setting-writer namerefs.
    # shellcheck disable=SC2034
    local -A OptionCommentCatalog=()
    local -a ChmodCommand=()
    local -a MoveCommand=()

    resolve_control_file_publication_path "$Path" PublishPath || return 21
    Directory="${PublishPath%/*}"
    BaseName="${PublishPath##*/}"
    [[ "$Directory" != "$PublishPath" ]] || Directory='.'
    [[ -d "$Directory" && -w "$Directory" ]] || return 21

    for ConfigKey in Language SshPort UseOxidized IgnoreOxiAccess OxidizedHome UseIdentityName backup_type UseIncremental export_format show_sensitive encrypt encrypt_type clear_dns_cache clear_console_history BackupRoot UseNetFolder MonthlyArchive LogLevel MainLogPath; do
        CanonicalValue=''
        validate_ordinary_config_value \
            "$ConfigKey" \
            "${ConfigIn[$ConfigKey]:-${DefaultValues[$ConfigKey]}}" \
            CanonicalValue || return 21
        CanonicalConfig["$ConfigKey"]="$CanonicalValue"
    done
    build_localization_catalog "${CanonicalConfig[Language]}" OptionCommentCatalog || return 21
    build_product_header "$UiWidth" ProductHeader || return 21
    PassportFile="${OptionCommentCatalog[option_passport_file]}"
    PassportPurpose="${OptionCommentCatalog[option_passport_purpose]}"

    if [[ -e "$Path" || -L "$Path" ]]; then
        trusted_input_configuration_object "$Path" || return 21
        ExistingConfig=()
        local Key
        if [[ "${RuntimeState[StartupConfigLoaded]:-false}" == true &&
              "$Path" == "${RuntimeState[OptionConfigPath]:-}" ]]; then
            for Key in "${!ParsedOptionConfig[@]}"; do
                ExistingConfig["$Key"]="${ParsedOptionConfig[$Key]}"
            done
            for Key in "${!ParsedOptionSeen[@]}"; do
                ExistingSeen["$Key"]="${ParsedOptionSeen[$Key]}"
            done
        else
            for Key in "${!DefaultValues[@]}"; do
                ExistingConfig["$Key"]="${DefaultValues[$Key]}"
            done
            parse_option_config "$Path" ExistingConfig ExistingSeen || return 21
        fi
        if [[ -n "${ExistingSeen[Login]+x}" ]]; then
            ExistingLoginPresent=true
        fi
        if [[ -n "${ExistingSeen[Password]+x}" ]]; then
            ExistingPasswordPresent=true
        fi
    fi

    create_atomic_temp_file "$Directory" "$BaseName" TempPath TempCleanupId || return 21
    {
        printf '%s\n' "$ProductHeader"
        printf '%s\n' "$PassportFile" "$PassportPurpose"
        printf '\n'
        for ConfigKey in Language SshPort UseOxidized IgnoreOxiAccess OxidizedHome UseIdentityName backup_type UseIncremental export_format show_sensitive encrypt encrypt_type clear_dns_cache clear_console_history BackupRoot UseNetFolder MonthlyArchive LogLevel MainLogPath; do
            write_canonical_option_setting OptionCommentCatalog "$ConfigKey" "${CanonicalConfig[$ConfigKey]}"
            printf '\n'
        done
        if [[ "$ExistingLoginPresent" == true || "$ExistingPasswordPresent" == true ]]; then
            if [[ "$ExistingLoginPresent" == true ]]; then
                write_canonical_option_setting OptionCommentCatalog Login "${ExistingConfig[Login]}"
            fi
            if [[ "$ExistingPasswordPresent" == true ]]; then
                [[ "$ExistingLoginPresent" == true ]] && printf '\n'
                write_canonical_option_setting OptionCommentCatalog Password "${ExistingConfig[Password]}"
            fi
        fi
    } > "$TempPath" || WriteStatus=$?
    if (( WriteStatus != 0 )); then
        return 21
    fi

    ChmodCommand=(chmod 0600 -- "$TempPath")
    "${ChmodCommand[@]}" || return 21
    [[ -f "$TempPath" && ! -L "$TempPath" && -O "$TempPath" ]] || return 21
    ValidationConfig=()
    local ValidationKey
    # Parsed through a nameref to validate the complete temporary file.
    # shellcheck disable=SC2034
    for ValidationKey in "${!DefaultValues[@]}"; do
        ValidationConfig["$ValidationKey"]="${DefaultValues[$ValidationKey]}"
    done
    parse_option_config "$TempPath" ValidationConfig || return 21
    MoveCommand=(mv -f -- "$TempPath" "$PublishPath")
    "${MoveCommand[@]}" || return 21
    unregister_cleanup_entry "$TempCleanupId" || :
    if [[ "$Path" == "${RuntimeState[OptionConfigPath]:-}" ]]; then
        ParsedOptionConfig=()
        ParsedOptionSeen=()
        for ConfigKey in "${!CanonicalConfig[@]}"; do
            ParsedOptionConfig["$ConfigKey"]="${CanonicalConfig[$ConfigKey]}"
            ParsedOptionSeen["$ConfigKey"]=1
        done
        if [[ "$ExistingLoginPresent" == true ]]; then
            ParsedOptionConfig[Login]="${ExistingConfig[Login]}"
            ParsedOptionSeen[Login]=1
        fi
        if [[ "$ExistingPasswordPresent" == true ]]; then
            ParsedOptionConfig[Password]="${ExistingConfig[Password]}"
            ParsedOptionSeen[Password]=1
        fi
        RuntimeState[StartupConfigLoaded]=true
        RuntimeState[StartupConfigExists]=true
        RuntimeState[StartupConfigUsable]=true
    fi
    return 0
}

# ==============================================================================
# DeviceList model, collection and publication
# ==============================================================================

# Назначение: Проверяет, существует ли пригодный regular devicelist.cfg без попытки его разобрать или изменить.
# shellcheck disable=SC2034  # AvailableOut is a nameref output.
device_list_object_available()
{
    local Path="$1"
    local -n AvailableOut="$2"

    AvailableOut=false
    [[ -e "$Path" || -L "$Path" ]] || return 0
    if ! trusted_input_configuration_object "$Path"; then
        record_warning unsafe_device_source_object
        return 23
    fi
    AvailableOut=true
    return 0
}

# Назначение: Удаляет динамические контексты устройств и обнуляет статистику/индексы перед новым сбором источника.
reset_device_collection()
{
    local DeviceId

    reset_device_name_claims
    for DeviceId in "${DeviceIds[@]}"; do
        if [[ "$DeviceId" =~ ^DeviceContext_[0-9]+$ ]]; then
            unset -v "$DeviceId"
        fi
    done
    DeviceIds=()
    SourceSeenKeys=()
    DeclaredNameClaims=()
    SourceStats=([Read]=0 [Accepted]=0 [Filtered]=0 [Skipped]=0)
    return 0
}

# Назначение: Разделяет строку по буквальному delimiter с сохранением пустых полей и возвращает массив через nameref.
# shellcheck disable=SC2034  # FieldsOut is a nameref output.
split_literal_fields()
{
    local Line="$1"
    local Delimiter="$2"
    local -n FieldsOut="$3"
    local Field=''
    local Character
    local Index

    FieldsOut=()
    [[ ${#Delimiter} -eq 1 ]] || return 25
    for ((Index=0; Index<${#Line}; Index++)); do
        Character="${Line:Index:1}"
        if [[ "$Character" == "$Delimiter" ]]; then
            FieldsOut+=("$Field")
            Field=''
        else
            Field+="$Character"
        fi
    done
    FieldsOut+=("$Field")
    return 0
}

# Назначение: Строит нормализованный ключ адреса/порта/пользователя для обнаружения повторяющихся записей.
device_duplicate_key()
{
    local -n KeyOut="$1"
    shift
    local Value

    KeyOut=''
    for Value in "$@"; do
        KeyOut+="${#Value}:$Value"
    done
    return 0
}

# Назначение: Проверяет поля одной записи, создаёт DeviceContext и учитывает принятые, пропущенные и ошибочные строки.
# Generated associative contexts are output state.
# shellcheck disable=SC2034
resolve_device_record()
{
    local DeclaredName="$1"
    local Address="$2"
    local InputUser="$3"
    local InputPassword="$4"
    local InputPort="$5"
    local Marker="$6"
    local SourceType="$7"
    local SourceLine="$8"
    local User="$InputUser"
    local Password="$InputPassword"
    local Port="$InputPort"
    local DuplicateKey=''
    local ContextName=''
    local PreviousName=''
    local ClaimedContext=''
    local NumericPort=0

    trim_external_whitespace "$DeclaredName" DeclaredName
    trim_external_whitespace "$Address" Address
    trim_external_whitespace "$Port" Port
    trim_external_whitespace "$Marker" Marker
    [[ -n "$Marker" ]] || Marker=MikroTik

    if [[ "${Marker,,}" != mikrotik ]]; then
        SourceStats[Filtered]="$((SourceStats[Filtered] + 1))"
        return 0
    fi

    [[ -n "$User" ]] || User="${EffectiveConfig[Login]}"
    [[ -n "$Password" ]] || Password="${EffectiveConfig[Password]}"
    [[ -n "$Port" ]] || Port="${EffectiveConfig[SshPort]}"

    if [[ -z "$DeclaredName" || -z "$Address" || -z "$User" || -z "$Password" ||
          ! "$Port" =~ ^[0-9]+$ ||
          "$DeclaredName" == *$'\t'* || "$Address" == *$'\t'* ||
          "$User" == *$'\t'* || "$Password" == *$'\t'* ]]; then
        SourceStats[Skipped]="$((SourceStats[Skipped] + 1))"
        record_warning invalid_device_record
        return 0
    fi
    NumericPort=$((10#$Port))
    if (( NumericPort < 1 || NumericPort > 65535 )); then
        SourceStats[Skipped]="$((SourceStats[Skipped] + 1))"
        record_warning invalid_device_record
        return 0
    fi
    Port="$NumericPort"

    device_duplicate_key DuplicateKey "$Address" "$User" "$Password" "$Port"
    if [[ -n "${SourceSeenKeys[$DuplicateKey]+x}" ]]; then
        ContextName="${SourceSeenKeys[$DuplicateKey]}"
        [[ "$ContextName" =~ ^DeviceContext_[0-9]+$ ]] || return 80
        local -n DuplicateDeviceOut="$ContextName"
        PreviousName="${DuplicateDeviceOut[DeclaredName]}"
        if [[ "${DeclaredNameClaims[$PreviousName]:-}" == "$ContextName" ]]; then
            unset 'DeclaredNameClaims[$PreviousName]'
        fi
        SourceStats[Skipped]="$((SourceStats[Skipped] + 1))"
        record_warning duplicate_device_record

        ClaimedContext="${DeclaredNameClaims[$DeclaredName]:-}"
        if [[ -n "$ClaimedContext" && "$ClaimedContext" != "$ContextName" ]]; then
            record_warning duplicate_declared_device_name
            unset 'SourceSeenKeys[$DuplicateKey]'
            local Index=0
            for ((Index=0; Index<${#DeviceIds[@]}; Index++)); do
                if [[ "${DeviceIds[Index]}" == "$ContextName" ]]; then
                    unset 'DeviceIds[Index]'
                    DeviceIds=("${DeviceIds[@]}")
                    break
                fi
            done
            unset -v "$ContextName"
            SourceStats[Accepted]="$((SourceStats[Accepted] - 1))"
            return 0
        fi

        DuplicateDeviceOut[DeclaredName]="$DeclaredName"
        DuplicateDeviceOut[Address]="$Address"
        DuplicateDeviceOut[User]="$User"
        DuplicateDeviceOut[Password]="$Password"
        DuplicateDeviceOut[Port]="$Port"
        DuplicateDeviceOut[SourceType]="$SourceType"
        DuplicateDeviceOut[SourceLine]="$SourceLine"
        DuplicateDeviceOut[InputUser]="$InputUser"
        DuplicateDeviceOut[InputPassword]="$InputPassword"
        DuplicateDeviceOut[InputPort]="$InputPort"
        DeclaredNameClaims["$DeclaredName"]="$ContextName"
        return 0
    fi

    if [[ -n "${DeclaredNameClaims[$DeclaredName]+x}" ]]; then
        SourceStats[Skipped]="$((SourceStats[Skipped] + 1))"
        record_warning duplicate_declared_device_name
        return 0
    fi

    RuntimeState[DeviceContextCounter]="$((${RuntimeState[DeviceContextCounter]:-0} + 1))"
    ContextName="DeviceContext_${RuntimeState[DeviceContextCounter]}"
    declare -gA "$ContextName"
    local -n DeviceOut="$ContextName"
    DeviceOut=()
    DeviceOut[DeclaredName]="$DeclaredName"
    DeviceOut[Address]="$Address"
    DeviceOut[User]="$User"
    DeviceOut[Password]="$Password"
    DeviceOut[Port]="$Port"
    DeviceOut[SourceType]="$SourceType"
    DeviceOut[SourceLine]="$SourceLine"
    DeviceOut[InputUser]="$InputUser"
    DeviceOut[InputPassword]="$InputPassword"
    DeviceOut[InputPort]="$InputPort"
    DeviceIds+=("$ContextName")
    SourceSeenKeys["$DuplicateKey"]="$ContextName"
    DeclaredNameClaims["$DeclaredName"]="$ContextName"
    SourceStats[Accepted]="$((SourceStats[Accepted] + 1))"
    return 0
}

# Назначение: Читает канонический DeviceList построчно и передаёт каждую запись общему resolver без исполнения содержимого.
load_canonical_device_list()
{
    local Path="$1"
    local SourceType="${2:-canonical_tsv}"
    local Line=''
    local Trimmed=''
    local ReadStatus=0
    local LineNumber=0
    local FirstLine=true
    local SourceAvailable=false
    local ProbeFd
    local -a Fields=()

    reset_device_collection
    [[ -e "$Path" || -L "$Path" ]] || return 22
    device_list_object_available "$Path" SourceAvailable || return $?
    [[ "$SourceAvailable" == true ]] || return 22
    exec {ProbeFd}< "$Path" 2>/dev/null || return 22
    exec {ProbeFd}<&-
    # With -d '', read succeeds on NUL; Bash variables cannot retain that byte.
    # A nonzero status may mean EOF or a read error, not validated text.
    if IFS= read -r -d '' Line < "$Path"; then
        return 23
    fi

    Line=''
    while true; do
        IFS= read -r Line
        ReadStatus=$?
        if (( ReadStatus != 0 )) && [[ -z "$Line" ]]; then
            break
        fi
        ((LineNumber++))
        if [[ "$FirstLine" == true ]]; then
            Line="${Line#$'\xEF\xBB\xBF'}"
            FirstLine=false
        fi
        Line="${Line%$'\r'}"
        trim_external_whitespace "$Line" Trimmed
        if [[ -z "$Trimmed" || "${Trimmed:0:1}" == '#' ]]; then
            (( ReadStatus == 0 )) || break
            continue
        fi

        SourceStats[Read]="$((SourceStats[Read] + 1))"
        split_literal_fields "$Line" $'\t' Fields || return 23
        resolve_device_record \
            "${Fields[0]:-}" "${Fields[1]:-}" "${Fields[2]:-}" \
            "${Fields[3]:-}" "${Fields[4]:-}" "${Fields[5]:-}" \
            "$SourceType" "$LineNumber"
        (( ReadStatus == 0 )) || break
    done < "$Path"

    if (( SourceStats[Read] == 0 || SourceStats[Accepted] == 0 )); then
        reset_device_collection
        return 23
    fi
    return 0
}

# Назначение: Атомарно публикует сгенерированный DeviceList в каноническом формате после импорта источника.
write_generated_device_list()
{
    local Path="$1"
    local PublishPath=''
    local Directory=''
    local BaseName=''
    local TempPath=''
    local TempCleanupId=''
    local DeviceId
    local TempHash=''
    local ExistingHash=''
    local WriterLanguage="${ParsedOptionConfig[Language]:-${DefaultValues[Language]:-auto}}"
    local ProductHeader=''
    local PassportFile=''
    local PassportPurpose=''
    local -A DeviceWriterCatalog=()
    local -a ChmodCommand=()
    local -a MoveCommand=()
    local -a HashCommand=()

    resolve_control_file_publication_path "$Path" PublishPath || return 35
    Directory="${PublishPath%/*}"
    BaseName="${PublishPath##*/}"
    [[ "$Directory" != "$PublishPath" ]] || Directory='.'
    [[ -d "$Directory" && -w "$Directory" ]] || return 35
    if [[ -e "$Path" || -L "$Path" ]]; then
        [[ -f "$Path" ]] || return 35
    fi
    (( ${#DeviceIds[@]} > 0 )) || return 80
    build_localization_catalog "$WriterLanguage" DeviceWriterCatalog || return 35
    build_product_header "$UiWidth" ProductHeader || return 35
    PassportFile="${DeviceWriterCatalog[device_passport_file]}"
    PassportPurpose="${DeviceWriterCatalog[device_passport_purpose]}"
    create_atomic_temp_file "$Directory" "$BaseName" TempPath TempCleanupId || return 37
    {
        printf '%s\n' "$ProductHeader"
        printf '%s\n' "$PassportFile" "$PassportPurpose"
        printf '\n'
        for DeviceId in "${DeviceIds[@]}"; do
            local -n Device="$DeviceId"
            printf '%s\t%s\t%s\t%s\t%s\tMikroTik\n' \
                "${Device[DeclaredName]}" "${Device[Address]}" \
                "${Device[InputUser]}" "${Device[InputPassword]}" "${Device[InputPort]}"
        done
    } > "$TempPath" || {
        discard_atomic_temp_file "$TempPath" "$TempCleanupId"
        return 37
    }
    ChmodCommand=(chmod 0600 -- "$TempPath")
    "${ChmodCommand[@]}" || {
        discard_atomic_temp_file "$TempPath" "$TempCleanupId"
        return 35
    }
    [[ -f "$TempPath" && ! -L "$TempPath" && -O "$TempPath" ]] || {
        discard_atomic_temp_file "$TempPath" "$TempCleanupId"
        return 80
    }

    load_canonical_device_list "$TempPath" generated_tsv || {
        discard_atomic_temp_file "$TempPath" "$TempCleanupId"
        reset_device_collection
        return 80
    }
    reset_device_collection
    command -v sha256sum >/dev/null 2>&1 || {
        discard_atomic_temp_file "$TempPath" "$TempCleanupId"
        return 80
    }
    HashCommand=(sha256sum -- "$TempPath")
    TempHash="$("${HashCommand[@]}")" || {
        discard_atomic_temp_file "$TempPath" "$TempCleanupId"
        return 37
    }
    TempHash="${TempHash%% *}"
    [[ "$TempHash" =~ ^[[:xdigit:]]{64}$ ]] || {
        discard_atomic_temp_file "$TempPath" "$TempCleanupId"
        return 37
    }
    if [[ -f "$PublishPath" ]]; then
        HashCommand=(sha256sum -- "$PublishPath")
        ExistingHash="$("${HashCommand[@]}")" || {
            discard_atomic_temp_file "$TempPath" "$TempCleanupId"
            return 37
        }
        ExistingHash="${ExistingHash%% *}"
        [[ "$ExistingHash" =~ ^[[:xdigit:]]{64}$ ]] || {
            discard_atomic_temp_file "$TempPath" "$TempCleanupId"
            return 37
        }
        if [[ "$TempHash" == "$ExistingHash" ]]; then
            discard_atomic_temp_file "$TempPath" "$TempCleanupId"
            return 0
        fi
    fi
    MoveCommand=(mv -f -- "$TempPath" "$PublishPath")
    "${MoveCommand[@]}" || {
        discard_atomic_temp_file "$TempPath" "$TempCleanupId"
        return 37
    }
    unregister_cleanup_entry "$TempCleanupId" || :
    return 0
}

# Назначение: Выбирает доступный canonical либо Oxidized-источник и при необходимости материализует DeviceList.
prepare_device_source()
{
    local SourceAvailable=false
    local Status=0
    local OxidizedHome="${EffectiveConfig[OxidizedHome]%/}"

    [[ "${ExecutionState[RunMode]}" == batch ]] || return 80
    reset_device_collection
    unset 'ExecutionState[PreparedDeviceSourcePath]' \
        'ExecutionState[PreparedDeviceSourceType]' \
        'ExecutionState[PreparedRead]' \
        'ExecutionState[PreparedAccepted]' \
        'ExecutionState[PreparedFiltered]' \
        'ExecutionState[PreparedSkipped]'
    ExecutionState[DeviceListEligibleForRun]=true
    if [[ "${EffectiveConfig[UseOxidized]}" != true ]]; then
        device_list_object_available "${RuntimeState[DeviceListPath]}" SourceAvailable || Status=$?
        (( Status == 0 )) || return "$Status"
        if [[ "$SourceAvailable" == true ]]; then
            ExecutionState[PreparedDeviceSourcePath]="${RuntimeState[DeviceListPath]}"
            ExecutionState[PreparedDeviceSourceType]=canonical_tsv
        fi
        return 0
    fi

    emit_runtime_log_event shell script main short '' log_oxidized_source \
        '' start '' none none '' '' '' '' primary || :
    ExecutionState[OxidizedConfigPath]="$OxidizedHome/config"
    ExecutionState[OxidizedRouterDbPath]="$OxidizedHome/router.db"
    Status=0
    emit_runtime_log_event shell script subevent full '' \
        log_oxidized_read_config '' ordinary 1 none none '' '' '' '' primary || :
    read_oxidized_config "${ExecutionState[OxidizedConfigPath]}" || Status=$?
    if (( Status != 0 )); then
        emit_runtime_log_event shell script subevent error '' \
            log_oxidized_read_config "$Status" error 1 none \
            none '' '' '' '' primary || :
    fi
    if (( Status == 0 )); then
        emit_runtime_log_event shell script subevent full '' \
            log_oxidized_import_database '' ordinary 2 none \
            none '' '' '' '' primary || :
        import_oxidized_csv "${ExecutionState[OxidizedRouterDbPath]}" || Status=$?
        if (( Status != 0 )); then
            emit_runtime_log_event shell script subevent error '' \
                log_oxidized_import_database "$Status" error 2 none \
                none '' '' '' '' primary || :
        fi
    fi
    if (( Status != 0 )); then
        emit_runtime_log_event shell script main short '' log_oxidized_source \
            "$Status" outcome '' none none '' '' '' '' primary || :
        promote_run_result "$Status"
        reset_device_collection
        if [[ "${EffectiveConfig[IgnoreOxiAccess]}" != true ]]; then
            ExecutionState[DeviceListEligibleForRun]=false
            return 0
        fi
        SourceAvailable=false
        Status=0
        device_list_object_available "${RuntimeState[DeviceListPath]}" SourceAvailable || Status=$?
        if (( Status != 0 )); then
            promote_run_result "$Status"
            return 0
        fi
        if [[ "$SourceAvailable" == true ]]; then
            ExecutionState[PreparedDeviceSourcePath]="${RuntimeState[DeviceListPath]}"
            ExecutionState[PreparedDeviceSourceType]=canonical_tsv
            ExecutionState[OxidizedFallback]=true
        fi
        return 0
    fi
    ExecutionState[PreparedRead]="${SourceStats[Read]}"
    ExecutionState[PreparedAccepted]="${SourceStats[Accepted]}"
    ExecutionState[PreparedFiltered]="${SourceStats[Filtered]}"
    ExecutionState[PreparedSkipped]="${SourceStats[Skipped]}"
    emit_runtime_log_event shell script subevent full '' \
        log_oxidized_publish_list '' ordinary 3 none \
        none '' '' '' '' primary || :
    write_generated_device_list "${RuntimeState[DeviceListPath]}" || {
        Status=$?
        emit_runtime_log_event shell script subevent error '' \
            log_oxidized_publish_list "$Status" error 3 none \
            none '' '' '' '' primary || :
        emit_runtime_log_event shell script main short '' log_oxidized_source \
            "$Status" outcome '' none none '' '' '' '' primary || :
        promote_run_result "$Status"
        reset_device_collection
        SourceAvailable=false
        Status=0
        device_list_object_available "${RuntimeState[DeviceListPath]}" SourceAvailable || Status=$?
        if (( Status != 0 )); then
            promote_run_result "$Status"
            return 0
        fi
        if [[ "$SourceAvailable" == true ]]; then
            ExecutionState[PreparedDeviceSourcePath]="${RuntimeState[DeviceListPath]}"
            ExecutionState[PreparedDeviceSourceType]=canonical_tsv
        fi
        return 0
    }
    emit_runtime_log_event shell script main short '' log_oxidized_source \
        0 outcome '' none none '' '' '' '' primary || :
    reset_device_collection
    ExecutionState[PreparedDeviceSourcePath]="${RuntimeState[DeviceListPath]}"
    ExecutionState[PreparedDeviceSourceType]=generated_tsv
    return 0
}

# Назначение: Сбрасывает прежнюю коллекцию, подготавливает источник и загружает все runnable-устройства.
load_device_collection()
{
    local Status=0

    [[ "${ExecutionState[RunMode]}" == batch ]] || return 80
    if [[ "${ExecutionState[DeviceListEligibleForRun]:-true}" != true ||
          -z "${ExecutionState[PreparedDeviceSourcePath]:-}" ]]; then
        reset_device_collection
        return 0
    fi
    load_canonical_device_list \
        "${ExecutionState[PreparedDeviceSourcePath]}" \
        "${ExecutionState[PreparedDeviceSourceType]}" || Status=$?
    (( Status == 0 )) || return "$Status"
    if [[ "${ExecutionState[PreparedDeviceSourceType]}" == generated_tsv ]]; then
        SourceStats[Read]="${ExecutionState[PreparedRead]}"
        SourceStats[Accepted]="${ExecutionState[PreparedAccepted]}"
        SourceStats[Filtered]="${ExecutionState[PreparedFiltered]}"
        SourceStats[Skipped]="${ExecutionState[PreparedSkipped]}"
    fi
    return 0
}

# Назначение: Выводит локализованные счётчики принятых, пропущенных, ошибочных и дублирующихся записей источника.
emit_source_summary()
{
    local Message

    localized_message source_loaded Message
    printf '%s %s/%s/%s/%s\n' "$Message" \
        "${SourceStats[Read]}" "${SourceStats[Accepted]}" \
        "${SourceStats[Filtered]}" "${SourceStats[Skipped]}" >&2
    return 0
}

# ==============================================================================
# Oxidized import and source translation
# ==============================================================================

# Назначение: Разбирает безопасное YAML-подобное scalar-значение без поддержки объектов, aliases или исполнения кода.
# shellcheck disable=SC2034  # ScalarOut is a nameref output.
decode_safe_scalar()
{
    local Value="$1"
    local -n ScalarOut="$2"
    local Character
    local Decoded=''
    local Index
    local NextCharacter
    local Backslash=$'\\'

    trim_external_whitespace "$Value" Value
    [[ -n "$Value" ]] || return 25
    if [[ "$Value" == \'* ]]; then
        [[ ${#Value} -ge 2 && "${Value: -1}" == "'" ]] || return 25
        Value="${Value:1:${#Value}-2}"
        Value="${Value//\'\'/\'}"
    elif [[ "$Value" == \"* ]]; then
        [[ ${#Value} -ge 2 && "${Value: -1}" == '"' ]] || return 25
        Value="${Value:1:${#Value}-2}"
        for ((Index=0; Index<${#Value}; Index++)); do
            Character="${Value:Index:1}"
            if [[ "$Character" != \\ ]]; then
                Decoded+="$Character"
                continue
            fi
            ((Index++))
            (( Index < ${#Value} )) || return 25
            NextCharacter="${Value:Index:1}"
            case "$NextCharacter" in
                '"') Decoded+='"' ;;
                "$Backslash") Decoded+="$NextCharacter" ;;
                t) Decoded+=$'\t' ;;
                *) return 25 ;;
            esac
        done
        Value="$Decoded"
    elif [[ "$Value" == ['!'\&\*\[\{\|\>\`]* ]]; then
        return 25
    fi
    ScalarOut="$Value"
    [[ -n "$ScalarOut" ]] || return 25
    return 0
}

# Назначение: Преобразует разрешённую escape-запись delimiter Oxidized в буквальную строку-разделитель.
# shellcheck disable=SC2034  # DelimiterOut is a nameref output.
decode_oxidized_delimiter()
{
    local Value="$1"
    local -n DelimiterOut="$2"
    local ParsedScalar=''

    trim_external_whitespace "$Value" Value
    if [[ "$Value" =~ ^!ruby/regexp[[:space:]]+/([^/])/$ ]]; then
        DelimiterOut="${BASH_REMATCH[1]}"
        case "$DelimiterOut" in
            '.'|'^'|'$'|'*'|'+'|'?'|'('|')'|'['|']'|'{'|'}'|'|') return 25 ;;
        esac
        return 0
    fi
    decode_safe_scalar "$Value" ParsedScalar || return 25
    case "$ParsedScalar" in
        '\t') DelimiterOut=$'\t' ;;
        *) DelimiterOut="$ParsedScalar" ;;
    esac
    [[ ${#DelimiterOut} -eq 1 ]] || return 25
    return 0
}

# Назначение: Проверяет ограниченный regexp сопоставления модели, исключая опасные или неподдержанные конструкции.
validate_oxidized_model_regexp()
{
    local Pattern="$1"
    local Character
    local Escaped=false
    local Index
    local RegexStatus=0
    local LC_ALL=C
    local Backslash=$'\\'

    [[ -n "$Pattern" ]] || return 25
    for ((Index=0; Index<${#Pattern}; Index++)); do
        Character="${Pattern:Index:1}"
        if [[ "$Escaped" == true ]]; then
            case "$Character" in
                '.'|'^'|'$'|'*'|'+'|'?'|'('|')'|'['|']'|'|'|"$Backslash"|'-') : ;;
                *) return 25 ;;
            esac
            Escaped=false
            continue
        fi
        case "$Character" in
            "$Backslash") Escaped=true ;;
            '{'|'}') return 25 ;;
            [[:cntrl:]]) return 25 ;;
        esac
    done
    [[ "$Escaped" == false && "$Pattern" != *'(?'* ]] || return 25

    [[ '' =~ $Pattern ]]
    RegexStatus=$?
    (( RegexStatus != 2 )) || return 25
    return 0
}

# Назначение: Добавляет проверенное правило exact/regexp в упорядоченные параллельные массивы модели.
add_oxidized_model_rule()
{
    local RuleType="$1"
    local RuleKey="$2"
    local RuleValue="$3"

    OxidizedModelRuleTypes+=("$RuleType")
    OxidizedModelRuleKeys+=("$RuleKey")
    OxidizedModelRuleValues+=("$RuleValue")
    return 0
}

# Назначение: Применяет правила в исходном порядке и возвращает тип backup для имени модели устройства.
# shellcheck disable=SC2034  # ModelOut is a nameref output.
map_oxidized_model()
{
    local InputModel="$1"
    local -n ModelOut="$2"
    local Index
    local RuleKey
    local RegexStatus=0
    local LC_ALL=C

    ModelOut="$InputModel"
    for ((Index=0; Index<${#OxidizedModelRuleTypes[@]}; Index++)); do
        RuleKey="${OxidizedModelRuleKeys[Index]}"
        case "${OxidizedModelRuleTypes[Index]}" in
            exact)
                [[ "$InputModel" == "$RuleKey" ]] || continue
                ;;
            regexp)
                RegexStatus=0
                [[ "$InputModel" =~ $RuleKey ]]
                RegexStatus=$?
                (( RegexStatus != 2 )) || return 80
                (( RegexStatus == 0 )) || continue
                ;;
            *) return 80 ;;
        esac
        ModelOut="${OxidizedModelRuleValues[Index]}"
        return 0
    done
    return 0
}

# Назначение: Читает нужное подмножество Oxidized YAML и формирует проверенную схему импорта CSV.
read_oxidized_config()
{
    local Path="$1"
    local Line=''
    local Body=''
    local Key=''
    local Value=''
    local Parent=''
    local FullPath=''
    local Scalar=''
    local ReadStatus=0
    local Indent=0
    local Top=0
    local Semantic
    local ProbeFd
    local ModelPattern=''
    local GlobalModelValue=''
    local GlobalModelPresent=false
    local IndentPrefix=''
    local -a StackIndents=(-1)
    local -a StackPaths=('')

    OxidizedSchema=()
    OxidizedModelRuleTypes=()
    OxidizedModelRuleKeys=()
    OxidizedModelRuleValues=()
    [[ -e "$Path" || -L "$Path" ]] || return 24
    [[ -f "$Path" && -r "$Path" ]] || return 24
    exec {ProbeFd}< "$Path" 2>/dev/null || return 24
    exec {ProbeFd}<&-
    # With -d '', read succeeds on NUL; Bash variables cannot retain that byte.
    # A nonzero status may mean EOF or a read error, not validated text.
    if IFS= read -r -d '' Line < "$Path"; then
        return 25
    fi

    Line=''
    while true; do
        IFS= read -r Line
        ReadStatus=$?
        if (( ReadStatus != 0 )) && [[ -z "$Line" ]]; then
            break
        fi
        Line="${Line%$'\r'}"
        trim_external_whitespace "$Line" Body
        if [[ -z "$Body" || "${Body:0:1}" == '#' || "$Body" == '---' ]]; then
            (( ReadStatus == 0 )) || break
            continue
        fi

        IndentPrefix="${Line%%[![:space:]]*}"
        [[ "$IndentPrefix" != *$'\t'* ]] || return 25
        Indent=${#IndentPrefix}
        while (( Top > 0 && StackIndents[Top] >= Indent )); do
            unset 'StackIndents[Top]' 'StackPaths[Top]'
            ((Top--))
        done
        Parent="${StackPaths[Top]}"

        if [[ "$Parent" == model_map && "$Body" == '!ruby/regexp'* ]]; then
            [[ "$Body" =~ ^!ruby/regexp[[:space:]]+/([^/]*)/:[[:space:]]*(.*)$ ]] || return 25
            ModelPattern="${BASH_REMATCH[1]}"
            Value="${BASH_REMATCH[2]}"
            validate_oxidized_model_regexp "$ModelPattern" || return 25
            decode_safe_scalar "$Value" Scalar || return 25
            add_oxidized_model_rule regexp "$ModelPattern" "$Scalar"
            (( ReadStatus == 0 )) || break
            continue
        fi

        [[ "$Body" =~ ^([A-Za-z0-9_.-]+):[[:space:]]*(.*)$ ]] || {
            [[ "$Parent" != model_map ]] || return 25
            (( ReadStatus == 0 )) || break
            continue
        }
        Key="${BASH_REMATCH[1]}"
        Value="${BASH_REMATCH[2]}"
        FullPath="${Parent:+$Parent.}$Key"
        trim_external_whitespace "$Value" Value
        if [[ -z "$Value" ]]; then
            ((Top++))
            StackIndents[Top]="$Indent"
            StackPaths[Top]="$FullPath"
        else
            case "$FullPath" in
                model)
                    GlobalModelValue="$Value"
                    GlobalModelPresent=true
                    ;;
                source.default|source.csv.file)
                    decode_safe_scalar "$Value" Scalar || return 25
                    OxidizedSchema["${FullPath#source.}"]="$Scalar"
                    ;;
                source.csv.delimiter)
                    decode_oxidized_delimiter "$Value" Scalar || return 25
                    OxidizedSchema[csv.delimiter]="$Scalar"
                    ;;
                source.csv.map.name|source.csv.map.model|source.csv.map.ip|source.csv.map.username|source.csv.map.password|source.csv.map.port)
                    decode_safe_scalar "$Value" Scalar || return 25
                    [[ "$Scalar" =~ ^[0-9]+$ && ${#Scalar} -le 9 ]] || return 25
                    Semantic="${FullPath##*.}"
                    OxidizedSchema["map.$Semantic"]="$((10#$Scalar))"
                    ;;
                model_map.*)
                    decode_safe_scalar "$Value" Scalar || return 25
                    add_oxidized_model_rule exact "${FullPath#model_map.}" "$Scalar"
                    ;;
            esac
        fi
        (( ReadStatus == 0 )) || break
    done < "$Path"

    [[ "${OxidizedSchema[default],,}" == csv ]] || return 25
    [[ -n "${OxidizedSchema[csv.delimiter]:-}" ]] || return 25
    [[ -n "${OxidizedSchema[map.name]+x}" ]] || return 25
    if [[ -z "${OxidizedSchema[map.model]+x}" ]]; then
        [[ "$GlobalModelPresent" == true ]] || return 25
        decode_safe_scalar "$GlobalModelValue" Scalar || return 25
        map_oxidized_model "$Scalar" Scalar || return $?
        [[ "${Scalar,,}" == routeros ]] || return 25
        OxidizedSchema[global.model]="$Scalar"
    fi
    return 0
}

# Назначение: Преобразует CSV Oxidized в общие DeviceContext, сохраняя статистику и политику дубликатов.
import_oxidized_csv()
{
    local Path="$1"
    local Delimiter="${OxidizedSchema[csv.delimiter]}"
    local Line=''
    local Trimmed=''
    local ReadStatus=0
    local LineNumber=0
    local Model=''
    local DeclaredName=''
    local Address=''
    local InputUser=''
    local InputPassword=''
    local InputPort=''
    local MapIndex
    local ProbeFd
    local -a Fields=()

    reset_device_collection
    [[ -e "$Path" || -L "$Path" ]] || return 24
    [[ -f "$Path" && -r "$Path" ]] || return 24
    exec {ProbeFd}< "$Path" 2>/dev/null || return 24
    exec {ProbeFd}<&-
    # With -d '', read succeeds on NUL; Bash variables cannot retain that byte.
    # A nonzero status may mean EOF or a read error, not validated text.
    if IFS= read -r -d '' Line < "$Path"; then
        return 25
    fi

    Line=''
    while true; do
        IFS= read -r Line
        ReadStatus=$?
        if (( ReadStatus != 0 )) && [[ -z "$Line" ]]; then
            break
        fi
        ((LineNumber++))
        Line="${Line%$'\r'}"
        if [[ -z "$Line" ]]; then
            (( ReadStatus == 0 )) || break
            continue
        fi
        trim_external_whitespace "$Line" Trimmed
        if [[ "${Trimmed:0:1}" == '#' ]]; then
            (( ReadStatus == 0 )) || break
            continue
        fi
        SourceStats[Read]="$((SourceStats[Read] + 1))"
        split_literal_fields "$Line" "$Delimiter" Fields || return 25

        MapIndex="${OxidizedSchema[map.name]}"
        DeclaredName="${Fields[MapIndex]:-}"
        if [[ -n "${OxidizedSchema[map.model]+x}" ]]; then
            MapIndex="${OxidizedSchema[map.model]}"
            Model="${Fields[MapIndex]:-}"
            trim_external_whitespace "$Model" Model
            if [[ -z "$Model" ]]; then
                SourceStats[Skipped]="$((SourceStats[Skipped] + 1))"
                record_warning invalid_device_record
                (( ReadStatus == 0 )) || break
                continue
            fi
            map_oxidized_model "$Model" Model || return $?
            if [[ "${Model,,}" != routeros ]]; then
                SourceStats[Filtered]="$((SourceStats[Filtered] + 1))"
                (( ReadStatus == 0 )) || break
                continue
            fi
        else
            Model="${OxidizedSchema[global.model]:-}"
            [[ "${Model,,}" == routeros ]] || return 80
        fi

        Address=''
        InputUser=''
        InputPassword=''
        InputPort=''
        if [[ -n "${OxidizedSchema[map.ip]+x}" ]]; then
            MapIndex="${OxidizedSchema[map.ip]}"
            Address="${Fields[MapIndex]:-}"
        fi
        trim_external_whitespace "$Address" Trimmed
        [[ -n "$Trimmed" ]] || Address="$DeclaredName"
        if [[ -n "${OxidizedSchema[map.username]+x}" ]]; then
            MapIndex="${OxidizedSchema[map.username]}"
            InputUser="${Fields[MapIndex]:-}"
        fi
        if [[ -n "${OxidizedSchema[map.password]+x}" ]]; then
            MapIndex="${OxidizedSchema[map.password]}"
            InputPassword="${Fields[MapIndex]:-}"
        fi
        if [[ -n "${OxidizedSchema[map.port]+x}" ]]; then
            MapIndex="${OxidizedSchema[map.port]}"
            InputPort="${Fields[MapIndex]:-}"
        fi
        resolve_device_record \
            "$DeclaredName" "$Address" "$InputUser" "$InputPassword" \
            "$InputPort" MikroTik oxidized_csv "$LineNumber"
        (( ReadStatus == 0 )) || break
    done < "$Path"

    if (( SourceStats[Read] == 0 || SourceStats[Accepted] == 0 )); then
        reset_device_collection
        return 25
    fi
    return 0
}

# ==============================================================================
# Device identity and filesystem-safe naming
# ==============================================================================

# Назначение: Проверяет в указанной locale требуемые операции Unicode case-folding и классов символов для безопасных имён.
check_naming_locale_capability_for_locale()
{
    local LocaleName="$1"
    local CyrillicUpper='Ё'
    local CyrillicLower=''
    local ArabicDigit='١'
    local LC_ALL="$LocaleName"

    [[ ${#CyrillicUpper} -eq 1 ]] || return 80
    [[ "$CyrillicUpper" == [[:alnum:]] ]] || return 80
    CyrillicLower="${CyrillicUpper,,}"
    [[ "$CyrillicLower" == 'ё' ]] || return 80
    [[ "$ArabicDigit" == [[:alnum:]] ]] || return 80
    return 0
}

# Назначение: Запускает capability-probe на доступной UTF-8 locale и запоминает фактически пригодное окружение.
check_naming_locale_capability()
{
    check_naming_locale_capability_for_locale C.UTF-8 || return 80
    RuntimeState[NamingLocaleReady]=true
    return 0
}

# Назначение: Лениво выполняет naming-probe один раз перед первой операцией нормализации имени.
ensure_naming_locale_capability()
{
    if [[ "${RuntimeState[NamingLocaleReady]:-false}" != true ]]; then
        check_naming_locale_capability || return 80
    fi
    return 0
}

# Назначение: Подтверждает, что переданное имя ссылается на объявленную ассоциативную таблицу DeviceContext.
device_context_exists()
{
    local DeviceId="$1"
    local CandidateId
    local Declaration=''
    local Found=false

    [[ "$DeviceId" =~ ^DeviceContext_[0-9]+$ ]] || return 80
    for CandidateId in "${DeviceIds[@]}"; do
        if [[ "$CandidateId" == "$DeviceId" ]]; then
            Found=true
            break
        fi
    done
    [[ "$Found" == true ]] || return 80
    Declaration="$(declare -p "$DeviceId" 2>/dev/null)" || return 80
    [[ "$Declaration" == "declare -A $DeviceId="* ]] || return 80
    return 0
}

# Назначение: Очищает таблицу занятых файловых имён перед построением новой коллекции устройств.
reset_device_name_claims()
{
    local DeviceId
    local Declaration=''

    if Declaration="$(declare -p DeviceNameClaims 2>/dev/null)" &&
       [[ "$Declaration" == 'declare -A DeviceNameClaims='* ]]; then
        DeviceNameClaims=()
    else
        declare -gA DeviceNameClaims=()
    fi

    for DeviceId in "${DeviceIds[@]}"; do
        [[ "$DeviceId" =~ ^DeviceContext_[0-9]+$ ]] || continue
        Declaration="$(declare -p "$DeviceId" 2>/dev/null)" || continue
        [[ "$Declaration" == "declare -A $DeviceId="* ]] || continue
        unset "${DeviceId}[DeviceName]" \
            "${DeviceId}[DeviceNameKey]" \
            "${DeviceId}[DeviceNameSource]"
    done
    return 0
}

# Назначение: Извлекает необязательное имя из конечной пары скобок адреса по строгому синтаксису.
# shellcheck disable=SC2034  # SelectedOut is a nameref output.
extract_parenthesized_device_name()
{
    local RawName="$1"
    local -n SelectedOut="$2"
    local Character
    local Group=''
    local Depth=0
    local Index
    local LC_ALL=C.UTF-8

    SelectedOut=''
    ensure_naming_locale_capability || return 80
    for ((Index=0; Index<${#RawName}; Index++)); do
        Character="${RawName:Index:1}"
        if [[ "$Character" == '(' ]]; then
            if (( Depth > 0 )); then
                Group+='('
            else
                Group=''
            fi
            ((Depth++))
            continue
        fi
        if [[ "$Character" == ')' ]]; then
            if (( Depth == 0 )); then
                continue
            fi
            ((Depth--))
            if (( Depth == 0 )); then
                if [[ -n "$Group" ]]; then
                    SelectedOut="$Group"
                    return 0
                fi
            else
                Group+=')'
            fi
            continue
        fi
        if (( Depth > 0 )); then
            Group+="$Character"
        fi
    done

    SelectedOut="$RawName"
    return 0
}

# Назначение: Нормализует Unicode/пробелы имени в стабильную файловую форму и возвращает её через nameref.
# shellcheck disable=SC2034  # NormalizedOut is a nameref output.
normalize_device_name()
{
    local SelectedName="$1"
    local -n NormalizedOut="$2"
    local Character
    local Index
    local NeedSeparator=false
    local Result=''
    local LC_ALL=C.UTF-8

    NormalizedOut=''
    ensure_naming_locale_capability || return 80
    for ((Index=0; Index<${#SelectedName}; Index++)); do
        Character="${SelectedName:Index:1}"
        if [[ "$Character" == [[:alnum:]] ||
              "$Character" == '.' || "$Character" == '_' || "$Character" == '-' ]]; then
            if [[ "$NeedSeparator" == true && -n "$Result" && "${Result: -1}" != '_' ]]; then
                Result+='_'
            fi
            NeedSeparator=false
            if [[ "$Character" == '_' && ( -z "$Result" || "${Result: -1}" == '_' ) ]]; then
                continue
            fi
            Result+="$Character"
        elif [[ -n "$Result" ]]; then
            NeedSeparator=true
        fi
    done

    while [[ "$Result" == [._-]* ]]; do
        Result="${Result:1}"
    done
    while [[ "$Result" == *[._] ]]; do
        Result="${Result:0:${#Result}-1}"
    done
    NormalizedOut="$Result"
    return 0
}

# Назначение: Запрещает пустые, служебные, управляющие и небезопасные для пути канонические имена.
validate_device_name()
{
    local DeviceName="$1"
    local Stem=''
    local FoldedStem=''
    local LC_ALL=C.UTF-8

    ensure_naming_locale_capability || return 80
    if [[ -z "$DeviceName" || "$DeviceName" == '.' || "$DeviceName" == '..' ||
          ${#DeviceName} -gt 32 ]]; then
        return 50
    fi
    Stem="${DeviceName%%.*}"
    FoldedStem="${Stem,,}"
    case "$FoldedStem" in
        con|prn|aux|nul|com[1-9]|lpt[1-9]) return 50 ;;
    esac
    return 0
}

# Назначение: Выбирает объявленное либо identity-имя, нормализует и проверяет его до файлового использования.
# shellcheck disable=SC2034  # Output values are returned through namerefs.
build_device_name()
{
    local RawName="$1"
    local -n DeviceNameOut="$2"
    local -n CollisionKeyOut="$3"
    local SelectedName=''
    local BuiltName=''
    local BuiltKey=''
    local LC_ALL=C.UTF-8

    DeviceNameOut=''
    CollisionKeyOut=''
    ensure_naming_locale_capability || return 80
    extract_parenthesized_device_name "$RawName" SelectedName || return $?
    normalize_device_name "$SelectedName" BuiltName || return $?
    validate_device_name "$BuiltName" || return $?
    BuiltKey="${BuiltName,,}"
    DeviceNameOut="$BuiltName"
    CollisionKeyOut="$BuiltKey"
    return 0
}

# Назначение: Закрепляет каноническое имя за устройством и отклоняет коллизии разных исходных записей.
# Generated associative contexts are intentional output state.
# shellcheck disable=SC2034
claim_device_name()
{
    local DeviceId="$1"
    local DeviceName="$2"
    local CollisionKey="$3"
    local DeviceNameSource="$4"
    local ExpectedKey=''
    local NormalizedName=''
    local ValidationStatus=0
    local LC_ALL=C.UTF-8

    ensure_naming_locale_capability || return 80
    device_context_exists "$DeviceId" || return 80
    [[ "$DeviceNameSource" == declared || "$DeviceNameSource" == identity ]] || return 80
    validate_device_name "$DeviceName" || ValidationStatus=$?
    (( ValidationStatus == 0 )) || return 80
    normalize_device_name "$DeviceName" NormalizedName || return 80
    [[ "$NormalizedName" == "$DeviceName" ]] || return 80
    ExpectedKey="${DeviceName,,}"
    [[ -n "$CollisionKey" && "$CollisionKey" == "$ExpectedKey" ]] || return 80

    local -n ClaimedContext="$DeviceId"
    if [[ -n "${ClaimedContext[DeviceNameKey]+x}" ]]; then
        if [[ "${ClaimedContext[DeviceName]}" == "$DeviceName" &&
              "${ClaimedContext[DeviceNameKey]}" == "$CollisionKey" &&
              "${ClaimedContext[DeviceNameSource]}" == "$DeviceNameSource" &&
              "${DeviceNameClaims[$CollisionKey]:-}" == "$DeviceId" ]]; then
            return 0
        fi
        return 80
    fi
    if [[ -n "${DeviceNameClaims[$CollisionKey]+x}" ]]; then
        [[ "${DeviceNameClaims[$CollisionKey]}" != "$DeviceId" ]] || return 80
        return 52
    fi

    DeviceNameClaims["$CollisionKey"]="$DeviceId"
    ClaimedContext[DeviceName]="$DeviceName"
    ClaimedContext[DeviceNameKey]="$CollisionKey"
    ClaimedContext[DeviceNameSource]="$DeviceNameSource"
    return 0
}

# Назначение: Строит и резервирует имя из явного поля DeviceList до сетевого обращения к RouterOS.
prepare_declared_device_name()
{
    local DeviceId="$1"
    local DeviceName=''
    local CollisionKey=''

    device_context_exists "$DeviceId" || return 80
    local -n DeclaredContext="$DeviceId"
    build_device_name "${DeclaredContext[DeclaredName]}" DeviceName CollisionKey || return $?
    claim_device_name "$DeviceId" "$DeviceName" "$CollisionKey" declared
}

# Назначение: Строит и резервирует имя по полученному RouterOS identity, когда явное имя отсутствует.
prepare_identity_device_name()
{
    local DeviceId="$1"
    local LiveIdentity="$2"
    local DeviceName=''
    local CollisionKey=''

    device_context_exists "$DeviceId" || return 80
    build_device_name "$LiveIdentity" DeviceName CollisionKey || return $?
    claim_device_name "$DeviceId" "$DeviceName" "$CollisionKey" identity
}

# ==============================================================================
# Storage qualification, probes and locks
# ==============================================================================

# Назначение: Возвращает type, device, inode, owner и mode объекта без разыменования недоверенной конечной ссылки.
# shellcheck disable=SC2034  # Output values are returned through namerefs.
stat_path_metadata()
{
    local Path="$1"
    local FollowLinks="$2"
    local -n TypeOut="$3"
    local -n OwnerOut="$4"
    local -n ModeOut="$5"
    local -n StatDeviceOut="$6"
    local -n InodeOut="$7"
    local Metadata=''
    local -a StatCommand=()

    if [[ "$FollowLinks" == true ]]; then
        StatCommand=(stat -Lc '%F|%u|%a|%d|%i' -- "$Path")
    else
        StatCommand=(stat -c '%F|%u|%a|%d|%i' -- "$Path")
    fi
    Metadata="$(LC_ALL=C "${StatCommand[@]}" 2>/dev/null)" || return 35
    IFS='|' read -r TypeOut OwnerOut ModeOut StatDeviceOut InodeOut <<< "$Metadata"
    [[ -n "$TypeOut" && "$OwnerOut" =~ ^[0-9]+$ && "$ModeOut" =~ ^[0-7]+$ &&
       "$StatDeviceOut" =~ ^[0-9]+$ && "$InodeOut" =~ ^[0-9]+$ ]] || return 35
    return 0
}

# Назначение: Вычисляет родительский каталог пути с корректной обработкой корня и одноуровневых имён.
# shellcheck disable=SC2034  # ParentOut is a nameref output.
path_parent()
{
    local Path="$1"
    local -n ParentOut="$2"

    while [[ "$Path" != / && "$Path" == */ ]]; do
        Path="${Path%/}"
    done
    if [[ "$Path" == / ]]; then
        ParentOut=/
    elif [[ "$Path" == */* ]]; then
        ParentOut="${Path%/*}"
        [[ -n "$ParentOut" ]] || ParentOut=/
    else
        ParentOut=.
    fi
    return 0
}

# Назначение: Классифицирует путь как absent/directory/regular/symlink/other для решений хранения.
# shellcheck disable=SC2034  # StateOut and AncestorOut are nameref outputs.
classify_path_object()
{
    local LogicalPath="$1"
    local -n StateOut="$2"
    local -n AncestorOut="$3"
    local Candidate="$LogicalPath"
    local Parent=''

    StateOut=''
    AncestorOut=''
    if [[ -L "$LogicalPath" ]]; then
        [[ -e "$LogicalPath" && -d "$LogicalPath" ]] || return 63
        StateOut=existing
        AncestorOut="$LogicalPath"
        return 0
    fi
    if [[ -e "$LogicalPath" ]]; then
        [[ -d "$LogicalPath" ]] || return 63
        StateOut=existing
        AncestorOut="$LogicalPath"
        return 0
    fi

    while [[ ! -e "$Candidate" && ! -L "$Candidate" ]]; do
        path_parent "$Candidate" Parent
        [[ "$Parent" != "$Candidate" ]] || return 63
        Candidate="$Parent"
    done
    if [[ -L "$Candidate" ]]; then
        [[ -e "$Candidate" && -d "$Candidate" ]] || return 63
    else
        [[ -d "$Candidate" ]] || return 63
    fi
    StateOut=missing
    AncestorOut="$Candidate"
    return 0
}

# Назначение: Разрешает BackupRoot относительно каталога программы, канонизирует существующую часть и сохраняет ожидаемый target.
# shellcheck disable=SC2034  # Output values are returned through namerefs.
resolve_backup_root()
{
    local BackupRoot="$1"
    local -n LogicalOut="$2"
    local -n ProposedOut="$3"
    local -n StateOut="$4"
    local -n AncestorOut="$5"
    local ResolvedLogical=''
    local ResolvedProposed=''
    local ResolvedState=''
    local ResolvedAncestor=''
    local Status=0
    local -a RealpathCommand=()

    [[ -n "$BackupRoot" ]] || return 80
    if [[ "$BackupRoot" == /* ]]; then
        ResolvedLogical="$BackupRoot"
    else
        ResolvedLogical="${RuntimeState[ProgramDirectory]}/$BackupRoot"
    fi
    RealpathCommand=(realpath -m -- "$ResolvedLogical")
    ResolvedProposed="$("${RealpathCommand[@]}" 2>/dev/null)" || {
        if [[ "${ExecutionState[RunMode]:-}" == single ]]; then
            return 33
        fi
        return 61
    }
    if [[ -z "$ResolvedProposed" ]]; then
        # A successful trusted realpath invocation cannot produce no path.
        return 80
    fi
    classify_path_object "$ResolvedLogical" ResolvedState ResolvedAncestor || Status=$?
    if (( Status != 0 )) || [[ "$ResolvedProposed" == / ]]; then
        if [[ "${ExecutionState[RunMode]:-}" == single ]]; then
            return 33
        fi
        return 63
    fi
    LogicalOut="$ResolvedLogical"
    ProposedOut="$ResolvedProposed"
    StateOut="$ResolvedState"
    AncestorOut="$ResolvedAncestor"
    return 0
}

# Назначение: Выбирает безопасный runtime-каталог для общих lock-файлов без размещения их в backup tree.
# shellcheck disable=SC2034  # DirectoryOut is a nameref output.
select_lock_runtime()
{
    local -n DirectoryOut="$1"

    DirectoryOut="/tmp/mikrotik-backup-${UID}"
    return 0
}

# Назначение: Создаёт/проверяет приватный каталог блокировок текущего пользователя и фиксирует его identity.
prepare_lock_runtime()
{
    local Directory="$1"
    local Type=''
    local Owner=''
    local Mode=''
    local Device=''
    local Inode=''
    local -a MkdirCommand=(mkdir -m 0700 -- "$Directory")
    local -a ChmodCommand=(chmod 0700 -- "$Directory")

    if [[ -L "$Directory" ]]; then
        return 35
    fi
    if [[ ! -e "$Directory" ]]; then
        "${MkdirCommand[@]}" 2>/dev/null || {
            [[ -d "$Directory" && ! -L "$Directory" ]] || return 35
        }
    fi
    stat_path_metadata "$Directory" false Type Owner Mode Device Inode || return 35
    [[ "$Type" == directory && "$Owner" == "$UID" ]] || return 35
    if [[ "$Mode" != 700 ]]; then
        "${ChmodCommand[@]}" 2>/dev/null || return 35
    fi
    stat_path_metadata "$Directory" false Type Owner Mode Device Inode || return 35
    [[ "$Type" == directory && "$Owner" == "$UID" && "$Mode" == 700 && ! -L "$Directory" ]] || return 35
    return 0
}

# Назначение: Получает стабильный SHA-256 идентификатор канонического ресурса для имени lock-файла.
# shellcheck disable=SC2034  # DigestOut is a nameref output.
build_lock_digest()
{
    local Namespace="$1"
    local CanonicalRoot="$2"
    local DeviceName="$3"
    local -n DigestOut="$4"
    local Frame=''
    local ComputedDigest=''
    local LC_ALL=C

    case "$Namespace" in
        root)
            [[ -z "$DeviceName" ]] || return 80
            Frame="root:${#CanonicalRoot}:$CanonicalRoot"
            ;;
        device)
            [[ -n "$DeviceName" ]] || return 80
            Frame="device:${#CanonicalRoot}:$CanonicalRoot:${#DeviceName}:$DeviceName"
            ;;
        *) return 80 ;;
    esac
    ComputedDigest="$(printf '%s' "$Frame" | sha256sum)" || return 80
    ComputedDigest="${ComputedDigest%% *}"
    [[ "$ComputedDigest" =~ ^[0-9a-f]{64}$ ]] || return 80
    DigestOut="$ComputedDigest"
    return 0
}

# Назначение: Строит /proc/self/fd-ссылку для проверки identity уже открытого файлового дескриптора.
# shellcheck disable=SC2034  # PathOut is a nameref output.
fd_path()
{
    local Fd="$1"
    local -n PathOut="$2"

    [[ "$Fd" =~ ^[0-9]+$ ]] || return 80
    PathOut="/proc/${BASHPID}/fd/${Fd}"
    return 0
}

# Назначение: Сверяет lock path с открытым fd, владельцем и сохранённым inode перед использованием блокировки.
validate_lock_path_fd_identity()
{
    local LockPath="$1"
    local Fd="$2"
    local FdPath=''
    local PathType=''
    local PathOwner=''
    local PathMode=''
    local PathDevice=''
    local PathInode=''
    local FdType=''
    local FdOwner=''
    local FdMode=''
    local FdDevice=''
    local FdInode=''

    [[ ! -L "$LockPath" && -f "$LockPath" ]] || return 35
    fd_path "$Fd" FdPath || return 80
    [[ -e "$FdPath" ]] || return 35
    stat_path_metadata "$LockPath" true PathType PathOwner PathMode PathDevice PathInode || return 35
    stat_path_metadata "$FdPath" true FdType FdOwner FdMode FdDevice FdInode || return 35
    [[ "$PathType" == regular*file && "$FdType" == regular*file ]] || return 35
    [[ "$PathOwner" == "$UID" && "$FdOwner" == "$UID" ]] || return 35
    [[ "$PathMode" == "$FdMode" ]] || return 35
    [[ "$PathDevice" == "$FdDevice" && "$PathInode" == "$FdInode" ]] || return 35
    return 0
}

# Назначение: Закрывает зарегистрированный lock descriptor и снимает его с общего cleanup-реестра.
close_lock_fd()
{
    local Fd="$1"

    [[ "$Fd" =~ ^[0-9]+$ ]] || return 80
    exec {Fd}>&-
    return 0
}

# Назначение: Безопасно открывает существующий либо создаёт новый lock-файл, не следуя подменённым путям.
# shellcheck disable=SC2034  # FdOut is a nameref output.
open_persistent_lock()
{
    local LockPath="$1"
    local -n FdOut="$2"
    local OpenedFd=0
    local FdPath=''
    local Type=''
    local Owner=''
    local Mode=''
    local Device=''
    local Inode=''
    local -a ChmodCommand=()

    FdOut=''
    if [[ -e "$LockPath" || -L "$LockPath" ]]; then
        [[ -f "$LockPath" && ! -L "$LockPath" && -O "$LockPath" ]] || return 35
    fi
    exec {OpenedFd}<>"$LockPath" || return 35
    validate_lock_path_fd_identity "$LockPath" "$OpenedFd" || {
        close_lock_fd "$OpenedFd"
        return 35
    }
    fd_path "$OpenedFd" FdPath || {
        close_lock_fd "$OpenedFd"
        return 80
    }
    stat_path_metadata "$FdPath" true Type Owner Mode Device Inode || {
        close_lock_fd "$OpenedFd"
        return 35
    }
    if [[ "$Mode" != 600 ]]; then
        ChmodCommand=(chmod 0600 -- "$FdPath")
        "${ChmodCommand[@]}" 2>/dev/null || {
            close_lock_fd "$OpenedFd"
            return 35
        }
    fi
    validate_lock_path_fd_identity "$LockPath" "$OpenedFd" || {
        close_lock_fd "$OpenedFd"
        return 35
    }
    stat_path_metadata "$FdPath" true Type Owner Mode Device Inode || {
        close_lock_fd "$OpenedFd"
        return 35
    }
    [[ "$Mode" == 600 ]] || {
        close_lock_fd "$OpenedFd"
        return 35
    }
    FdOut="$OpenedFd"
    return 0
}

# Назначение: Берёт неблокирующий flock на проверенном persistent lock и возвращает владение fd вызывающему коду.
# shellcheck disable=SC2034  # FdOut and CleanupIdOut are nameref outputs.
acquire_lock_file()
{
    local LockPath="$1"
    local LockMode="$2"
    local -n FdOut="$3"
    local -n CleanupIdOut="$4"
    local AcquiredFd=''
    local CleanupEntryId=''
    local Status=0
    local -a FlockCommand=(flock --conflict-exit-code 32 -n)

    case "$LockMode" in
        shared) FlockCommand+=(-s) ;;
        exclusive) FlockCommand+=(-x) ;;
        *) return 80 ;;
    esac
    open_persistent_lock "$LockPath" AcquiredFd || return $?
    FlockCommand+=("$AcquiredFd")
    "${FlockCommand[@]}" || Status=$?
    if (( Status != 0 )); then
        close_lock_fd "$AcquiredFd"
        (( Status == 32 )) && return 32
        return 35
    fi
    register_cleanup_fd "$AcquiredFd" CleanupEntryId || {
        close_lock_fd "$AcquiredFd"
        return 80
    }
    FdOut="$AcquiredFd"
    CleanupIdOut="$CleanupEntryId"
    return 0
}

# Назначение: Извлекает уже закреплённое безопасное имя устройства для построения device-lock.
# shellcheck disable=SC2034  # Output values are returned through namerefs.
resolve_claimed_device_identity()
{
    local RequestedName="$1"
    local -n DeviceIdOut="$2"
    local -n DeviceNameOut="$3"
    local RequestedKey=''
    local ResolvedDeviceId=''
    local StoredName=''
    local StoredKey=''
    local NormalizedName=''
    local LC_ALL=C.UTF-8

    DeviceIdOut=''
    DeviceNameOut=''
    validate_device_name "$RequestedName" >/dev/null 2>&1 || return 80
    RequestedKey="${RequestedName,,}"
    [[ -n "${DeviceNameClaims[$RequestedKey]+x}" ]] || return 80
    ResolvedDeviceId="${DeviceNameClaims[$RequestedKey]}"
    device_context_exists "$ResolvedDeviceId" || return 80
    local -n ClaimedDeviceContext="$ResolvedDeviceId"
    [[ -n "${ClaimedDeviceContext[DeviceName]+x}" &&
       -n "${ClaimedDeviceContext[DeviceNameKey]+x}" &&
       -n "${ClaimedDeviceContext[DeviceNameSource]+x}" ]] || return 80
    StoredName="${ClaimedDeviceContext[DeviceName]}"
    StoredKey="${ClaimedDeviceContext[DeviceNameKey]}"
    validate_device_name "$StoredName" >/dev/null 2>&1 || return 80
    normalize_device_name "$StoredName" NormalizedName || return 80
    [[ "$NormalizedName" == "$StoredName" &&
       "$StoredKey" == "${StoredName,,}" &&
       "$RequestedKey" == "$StoredKey" &&
       "${DeviceNameClaims[$StoredKey]:-}" == "$ResolvedDeviceId" ]] || return 80
    [[ "${ClaimedDeviceContext[DeviceNameSource]}" == declared ||
       "${ClaimedDeviceContext[DeviceNameSource]}" == identity ]] || return 80
    DeviceIdOut="$ResolvedDeviceId"
    DeviceNameOut="$StoredName"
    return 0
}

# Назначение: Берёт единственную блокировку канонического BackupRoot на период квалификации общего хранилища.
acquire_root_lock()
{
    local LockMode="$1"
    local Digest=''
    local LockPath=''
    local Fd=''
    local CleanupId=''

    [[ "$LockMode" == shared || "$LockMode" == exclusive ]] || return 80
    [[ -n "${StorageContext[ProposedRoot]:-}" && -n "${LockContext[RuntimeDirectory]:-}" ]] || return 80
    [[ "${LockContext[RootHeld]:-false}" != true ]] || return 80
    build_lock_digest root "${StorageContext[ProposedRoot]}" '' Digest || return $?
    LockPath="${LockContext[RuntimeDirectory]}/$Digest.lock"
    acquire_lock_file "$LockPath" "$LockMode" Fd CleanupId || return $?
    LockContext[RootDigest]="$Digest"
    LockContext[RootPath]="$LockPath"
    LockContext[RootFd]="$Fd"
    LockContext[RootCleanupId]="$CleanupId"
    LockContext[RootMode]="$LockMode"
    LockContext[RootHeld]=true
    return 0
}

# Назначение: Берёт отдельную блокировку каталога устройства, позволяя безопасную последовательную обработку batch.
acquire_device_lock()
{
    local RequestedName="$1"
    local DeviceId=''
    local DeviceName=''
    local Digest=''
    local LockPath=''
    local Fd=''
    local CleanupId=''

    [[ "${ExecutionState[RunMode]:-}" == single &&
       "${LockContext[RootHeld]:-false}" == true &&
       "${LockContext[RootMode]:-}" == shared ]] || return 80
    [[ -n "${StorageContext[CanonicalRoot]:-}" ]] || return 80
    resolve_claimed_device_identity "$RequestedName" DeviceId DeviceName || return 80
    : "$DeviceId"
    [[ "${LockContext[DeviceHeld]:-false}" != true ]] || return 80
    build_lock_digest device "${StorageContext[CanonicalRoot]}" "$DeviceName" Digest || return $?
    LockPath="${LockContext[RuntimeDirectory]}/$Digest.lock"
    acquire_lock_file "$LockPath" exclusive Fd CleanupId || return $?
    LockContext[DeviceDigest]="$Digest"
    LockContext[DevicePath]="$LockPath"
    LockContext[DeviceFd]="$Fd"
    LockContext[DeviceCleanupId]="$CleanupId"
    LockContext[DeviceHeld]=true
    return 0
}

# Назначение: Освобождает flock, закрывает fd и очищает переданную переменную дескриптора.
release_lock_fd()
{
    local Fd="$1"
    local CleanupId="$2"

    close_lock_fd "$Fd" || return $?
    unregister_cleanup_entry "$CleanupId"
    return 0
}

# Назначение: Запрашивает одно поле findmnt для пути с машинно-однозначным выводом и строгим числом строк.
# shellcheck disable=SC2034  # ValueOut is a nameref output.
query_mount_field()
{
    local Path="$1"
    local Field="$2"
    local -n ValueOut="$3"
    local Value=''
    local -a FindmntCommand=(findmnt -n -f -r -T "$Path" -o "$Field")

    case "$Field" in
        ID|TARGET|SOURCE|FSTYPE) : ;;
        *) return 80 ;;
    esac
    Value="$("${FindmntCommand[@]}" 2>/dev/null)" || return 62
    [[ -n "$Value" && "$Value" != *$'\n'* ]] || return 62
    ValueOut="$Value"
    return 0
}

# Назначение: Собирает source/target/fstype/options ближайшего mount и возвращает их вызывающему коду.
# shellcheck disable=SC2034  # MountOut is a nameref output context.
inspect_mount()
{
    local Path="$1"
    local -n MountOut="$2"
    local FirstId=''
    local FinalId=''
    local Target=''
    local Source=''
    local Filesystem=''

    MountOut=()
    query_mount_field "$Path" ID FirstId || return 62
    [[ "$FirstId" =~ ^[0-9]+$ ]] || return 62
    query_mount_field "$Path" TARGET Target || return 62
    query_mount_field "$Path" SOURCE Source || return 62
    query_mount_field "$Path" FSTYPE Filesystem || return 62
    query_mount_field "$Path" ID FinalId || return 62
    [[ "$FinalId" =~ ^[0-9]+$ && "$FirstId" == "$FinalId" ]] || return 62
    MountOut["ID"]="$FirstId"
    MountOut["TARGET"]="$Target"
    MountOut["SOURCE"]="$Source"
    MountOut["FSTYPE"]="$Filesystem"
    return 0
}

# Назначение: Сравнивает два набора mount-атрибутов, чтобы обнаружить смену или отвал сетевого хранилища.
same_mount_identity()
{
    local ExpectedName="$1"
    local ActualName="$2"
    local -n ExpectedMountRef="$ExpectedName"
    local -n ActualMountRef="$ActualName"
    local Field

    for Field in ID TARGET SOURCE FSTYPE; do
        [[ -n "${ExpectedMountRef[$Field]+x}" &&
           "${ExpectedMountRef[$Field]}" == "${ActualMountRef[$Field]:-}" ]] || return 62
    done
    return 0
}

# Назначение: Поднимается по отсутствующему пути до ближайшего существующего каталога для первичной проверки mount.
# shellcheck disable=SC2034  # AncestorOut is a nameref output.
find_deepest_existing_directory()
{
    local LogicalPath="$1"
    local -n AncestorOut="$2"
    local PathState=''
    local ExistingAncestor=''
    local Canonical=''
    local -a RealpathCommand=()

    classify_path_object "$LogicalPath" PathState ExistingAncestor || return 62
    RealpathCommand=(realpath -e -- "$ExistingAncestor")
    Canonical="$("${RealpathCommand[@]}" 2>/dev/null)" || return 62
    [[ -d "$Canonical" ]] || return 62
    AncestorOut="$Canonical"
    return 0
}

# Назначение: Выполняет ограниченное чтение каталога как best-effort триггер автомонтирования.
run_activation_trigger()
{
    local LogicalPath="$1"
    local -a TriggerCommand=(
        timeout --foreground --signal=TERM --kill-after=1s 3s
        stat -L -- "$LogicalPath"
    )

    "${TriggerCommand[@]}" >/dev/null 2>&1
}

# Назначение: Даёт автомонтированию короткое фиксированное время проявить mount после trigger.
activation_delay()
{
    sleep 1
}

# Назначение: Повторно инспектирует сетевой корень после trigger и подтверждает ожидаемую смену mount identity.
activate_network_root()
{
    local LogicalPath="$1"
    local Attempt
    local Ancestor=''
    local TriggerStatus=0
    local -A DefaultMount=()
    local -A CandidateMount=()

    inspect_mount / DefaultMount || return 62
    for ((Attempt=1; Attempt<=3; Attempt++)); do
        TriggerStatus=0
        run_activation_trigger "$LogicalPath" || TriggerStatus=$?
        : "$TriggerStatus"
        Ancestor=''
        if find_deepest_existing_directory "$LogicalPath" Ancestor &&
           inspect_mount "$Ancestor" CandidateMount &&
           [[ "${CandidateMount[ID]}" != "${DefaultMount[ID]}" ]]; then
            StorageContext[QualifiedMountID]="${CandidateMount[ID]}"
            StorageContext[QualifiedMountTARGET]="${CandidateMount[TARGET]}"
            StorageContext[QualifiedMountSOURCE]="${CandidateMount[SOURCE]}"
            StorageContext[QualifiedMountFSTYPE]="${CandidateMount[FSTYPE]}"
            StorageContext[ActivationAttempt]="$Attempt"
            return 0
        fi
        if (( Attempt < 3 )); then
            activation_delay
        fi
    done
    return 62
}

# Назначение: Сохраняет пустой test seam непосредственно перед созданием probe-объекта.
probe_before_create_hook()
{
    :
}

# Назначение: Сохраняет пустой test seam после создания probe и до подтверждения его identity.
probe_after_create_hook()
{
    :
}

# Назначение: Создаёт probe-файл с noclobber, чтобы не присвоить существующий пользовательский объект.
exclusive_create_probe_file()
{
    local Path="$1"

    attempt_noclobber_redirection "$Path"
}

# Назначение: Удаляет только только что созданный probe при сбое его регистрации, предварительно сверяя identity.
remove_just_created_probe_object()
{
    local Type="$1"
    local Path="$2"
    local ExpectedDevice="$3"
    local ExpectedInode="$4"
    local ActualDevice=''
    local ActualInode=''
    local -a RemoveCommand=()

    case "$Type" in
        file|directory) ;;
        *) return 80 ;;
    esac
    [[ "$ExpectedDevice" =~ ^[0-9]+$ &&
       "$ExpectedInode" =~ ^[0-9]+$ ]] || return 35
    cleanup_path_identity "$Path" ActualDevice ActualInode || return 35
    [[ "$ActualDevice" == "$ExpectedDevice" &&
       "$ActualInode" == "$ExpectedInode" ]] || return 35
    case "$Type" in
        file)
            [[ -f "$Path" && ! -L "$Path" ]] || return 35
            RemoveCommand=(rm -f -- "$Path")
            ;;
        directory)
            [[ -d "$Path" && ! -L "$Path" ]] || return 35
            RemoveCommand=(rmdir -- "$Path")
            ;;
    esac
    "${RemoveCommand[@]}" 2>/dev/null || return 35
    return 0
}

# Назначение: Создаёт файл/каталог probe, регистрирует cleanup и помечает владение в сигналобезопасной последовательности.
# shellcheck disable=SC2034  # Output values are returned through namerefs.
create_owned_probe_object()
{
    local Type="$1"
    local Path="$2"
    local -n EntryIdOut="$3"
    local -n CreatedOut="$4"
    local -n CollisionOut="$5"
    local EntryId=''
    local Device=''
    local Inode=''
    local CreateStatus=0
    local IdentityStatus=0
    local RecoveryStatus=0
    local DeferralStatus=0
    local CreateSucceeded=false
    local -a CreateCommand=()

    EntryIdOut=''
    CreatedOut=false
    CollisionOut=false
    [[ "$Type" == directory || "$Type" == file ]] || return 80
    register_cleanup_entry "$Type" "$Path" false '' '' EntryId || return $?
    begin_signal_deferral || DeferralStatus=$?
    if (( DeferralStatus != 0 )); then
        unregister_cleanup_entry "$EntryId" || :
        return "$DeferralStatus"
    fi
    probe_before_create_hook "$Type" "$Path"
    case "$Type" in
        directory)
            CreateCommand=(mkdir -m 0700 -- "$Path")
            "${CreateCommand[@]}" 2>/dev/null || CreateStatus=$?
            ;;
        file)
            exclusive_create_probe_file "$Path" || CreateStatus=$?
            ;;
    esac
    if (( CreateStatus == 0 )); then
        CreateSucceeded=true
        cleanup_path_identity "$Path" Device Inode || IdentityStatus=$?
        if (( IdentityStatus == 0 )); then
            mark_cleanup_entry_owned "$EntryId" "$Device" "$Inode" || IdentityStatus=$?
        fi
        probe_after_create_hook "$Type" "$Path"
    fi

    if [[ "$CreateSucceeded" == true && $IdentityStatus -ne 0 ]]; then
        remove_just_created_probe_object \
            "$Type" "$Path" "$Device" "$Inode" || RecoveryStatus=$?
        unregister_cleanup_entry "$EntryId" || RecoveryStatus=80
    elif [[ "$CreateSucceeded" != true ]]; then
        if [[ -e "$Path" || -L "$Path" ]]; then
            CollisionOut=true
        fi
        unregister_cleanup_entry "$EntryId" || RecoveryStatus=80
    fi
    end_signal_deferral || DeferralStatus=$?
    (( DeferralStatus == 0 )) || return "$DeferralStatus"

    if [[ "$CreateSucceeded" == true && $IdentityStatus -eq 0 ]]; then
        EntryIdOut="$EntryId"
        CreatedOut=true
        return 0
    fi
    if [[ "$CreateSucceeded" == true ]]; then
        EntryIdOut="$EntryId"
        (( IdentityStatus == 80 || RecoveryStatus == 80 )) && return 80
        return 35
    fi
    EntryIdOut="$EntryId"
    (( CreateStatus == 80 || RecoveryStatus == 80 )) && return 80
    return 0
}

# Назначение: Записывает случайный marker в принадлежащий probe-файл и синхронизирует видимый объём данных.
probe_write_marker()
{
    local Path="$1"
    local Marker="$2"

    printf '%s' "$Marker" > "$Path"
}

# Назначение: Считывает marker из probe-файла для проверки целостности read-after-write.
# shellcheck disable=SC2034  # MarkerOut is a nameref output.
probe_read_marker()
{
    local Path="$1"
    local -n MarkerOut="$2"

    [[ -r "$Path" ]] || return 35
    MarkerOut="$(<"$Path")" || return 35
    return 0
}

# Назначение: Удаляет проверенный probe-файл без расширения допустимой цели удаления.
probe_remove_file()
{
    local Path="$1"
    local -a RemoveCommand=(rm -f -- "$Path")

    "${RemoveCommand[@]}"
}

# Назначение: Удаляет пустой проверенный probe-каталог после завершения проверки записи.
probe_remove_directory()
{
    local Path="$1"
    local -a RemoveCommand=(rmdir -- "$Path")

    "${RemoveCommand[@]}"
}

# Назначение: Сверяет cleanup identity, удаляет принадлежащий probe и снимает регистрацию.
remove_owned_probe_entry()
{
    local EntryId="$1"
    local -n ProbeCleanupEntry="$EntryId"
    local Status=0

    [[ "${ProbeCleanupEntry[Active]:-false}" == true &&
       "${ProbeCleanupEntry[Owned]:-false}" == true ]] || return 35
    cleanup_entry_matches_path "$EntryId" || return 35
    case "${ProbeCleanupEntry[Type]}" in
        file) probe_remove_file "${ProbeCleanupEntry[Value]}" || Status=$? ;;
        symlink) probe_remove_file "${ProbeCleanupEntry[Value]}" || Status=$? ;;
        directory) probe_remove_directory "${ProbeCleanupEntry[Value]}" || Status=$? ;;
        *) return 80 ;;
    esac
    (( Status == 0 )) || return 35
    ProbeCleanupEntry[Active]=false
    return 0
}

# Назначение: Завершает probe при любом результате, сохраняя первый код ошибки создания/проверки/удаления.
cleanup_private_probe()
{
    local FileEntryId="$1"
    local DirectoryEntryId="$2"
    local Status=0
    local SubordinateStatus=0

    if [[ -n "$FileEntryId" ]]; then
        SubordinateStatus=0
        remove_owned_probe_entry "$FileEntryId" || SubordinateStatus=$?
        (( SubordinateStatus == 80 )) && Status=80
        (( SubordinateStatus == 0 || SubordinateStatus == 80 )) || Status=35
    fi
    if [[ -n "$DirectoryEntryId" ]]; then
        SubordinateStatus=0
        remove_owned_probe_entry "$DirectoryEntryId" || SubordinateStatus=$?
        (( SubordinateStatus == 80 )) && Status=80
        if (( SubordinateStatus != 0 && SubordinateStatus != 80 && Status != 80 )); then
            Status=35
        fi
    fi
    return "$Status"
}

# Назначение: Строит уникальное скрытое имя probe внутри ровно того каталога, который проверяется.
# shellcheck disable=SC2034  # CandidateOut is a nameref output.
build_probe_candidate()
{
    local BaseDirectory="$1"
    local Attempt="$2"
    local -n CandidateOut="$3"

    CandidateOut="$BaseDirectory/.mikrotik-backup.probe.${UID}.${BASHPID}.${RANDOM}.${Attempt}"
    return 0
}

# Назначение: Проверяет эксклюзивное создание, запись, чтение и удаление в каталоге без затрагивания пользовательских файлов.
run_private_probe()
{
    local BaseDirectory="$1"
    local FailureCode="$2"
    local Attempt
    local ProbeDirectory=''
    local ProbeFile=''
    local DirectoryEntryId=''
    local FileEntryId=''
    local Created=false
    local Collision=false
    local Marker='mikrotik-storage-probe-v2'
    local ReadMarker=''
    local Status=0
    local SubordinateStatus=0
    local CleanupStatus=0

    for ((Attempt=0; Attempt<100; Attempt++)); do
        SubordinateStatus=0
        build_probe_candidate "$BaseDirectory" "$Attempt" ProbeDirectory || SubordinateStatus=$?
        (( SubordinateStatus == 80 )) && return 80
        (( SubordinateStatus == 0 )) || return "$FailureCode"
        DirectoryEntryId=''
        Created=false
        Collision=false
        SubordinateStatus=0
        create_owned_probe_object directory "$ProbeDirectory" DirectoryEntryId Created Collision || SubordinateStatus=$?
        (( SubordinateStatus == 80 )) && return 80
        (( SubordinateStatus == 0 )) || return "$FailureCode"
        if [[ "$Created" == true ]]; then
            break
        fi
        [[ "$Collision" == true ]] || return "$FailureCode"
    done
    [[ "$Created" == true ]] || return "$FailureCode"

    ProbeFile="$ProbeDirectory/write"
    SubordinateStatus=0
    create_owned_probe_object file "$ProbeFile" FileEntryId Created Collision || SubordinateStatus=$?
    if (( SubordinateStatus != 0 )); then
        CleanupStatus=0
        remove_owned_probe_entry "$DirectoryEntryId" >/dev/null 2>&1 || CleanupStatus=$?
        (( SubordinateStatus == 80 || CleanupStatus == 80 )) && return 80
        return "$FailureCode"
    fi
    if [[ "$Created" != true ]]; then
        CleanupStatus=0
        remove_owned_probe_entry "$DirectoryEntryId" >/dev/null 2>&1 || CleanupStatus=$?
        (( CleanupStatus == 80 )) && return 80
        return "$FailureCode"
    fi

    probe_write_marker "$ProbeFile" "$Marker" || Status=$?
    if (( Status == 0 )); then
        probe_read_marker "$ProbeFile" ReadMarker || Status=$?
    fi
    if (( Status == 0 )) && [[ "$ReadMarker" != "$Marker" ]]; then
        Status=35
    fi
    CleanupStatus=0
    cleanup_private_probe "$FileEntryId" "$DirectoryEntryId" || CleanupStatus=$?
    (( Status == 80 || CleanupStatus == 80 )) && return 80
    (( CleanupStatus == 0 )) || Status=35
    (( Status == 0 )) || return "$FailureCode"
    return 0
}

# Назначение: Нормализует внутренние storage-ошибки в публичный код текущей фазы или сохраняет stop-сигнал.
# shellcheck disable=SC2034  # CodeOut is a nameref output.
storage_phase_code()
{
    local Phase="$1"
    local -n CodeOut="$2"

    case "$Phase" in
        single_preflight) CodeOut=36 ;;
        batch_preflight) CodeOut=63 ;;
        active) CodeOut=65 ;;
        *) return 80 ;;
    esac
    return 0
}

# Назначение: Повторно сверяет канонический root, mount identity и lock после потенциально изменившей среду операции.
# shellcheck disable=SC2034  # Mount snapshots are passed by name to same_mount_identity.
verify_common_root_invariants()
{
    local FailureCode="$1"
    local Canonical=''
    local Type=''
    local Owner=''
    local Mode=''
    local Device=''
    local Inode=''
    local -A ExpectedMount=()
    local -A ActualMount=()
    local -a RealpathCommand=(realpath -e -- "${StorageContext[LogicalRoot]:-}")

    [[ -n "${StorageContext[CanonicalRoot]:-}" ]] || return 80
    Canonical="$("${RealpathCommand[@]}" 2>/dev/null)" || return "$FailureCode"
    [[ "$Canonical" == "${StorageContext[CanonicalRoot]}" && "$Canonical" != / && -d "$Canonical" ]] || return "$FailureCode"
    stat_path_metadata "$Canonical" true Type Owner Mode Device Inode || return "$FailureCode"
    [[ "$Type" == directory && "$Device" == "${StorageContext[RootDevice]}" &&
       "$Inode" == "${StorageContext[RootInode]}" ]] || return "$FailureCode"
    if [[ "${StorageContext[NetworkMode]:-false}" == true ]]; then
        ExpectedMount[ID]="${StorageContext[MountID]}"
        ExpectedMount[TARGET]="${StorageContext[MountTARGET]}"
        ExpectedMount[SOURCE]="${StorageContext[MountSOURCE]}"
        ExpectedMount[FSTYPE]="${StorageContext[MountFSTYPE]}"
        inspect_mount "$Canonical" ActualMount || return "$FailureCode"
        same_mount_identity ExpectedMount ActualMount || return "$FailureCode"
    fi
    [[ -x "$Canonical" && -w "$Canonical" ]] || return "$FailureCode"
    return 0
}

# Назначение: Запускает приватный probe корня и переводит наблюдаемые отказы в контрактный storage-результат.
probe_storage_root()
{
    local Phase="$1"
    local FailureCode=0
    local Status=0

    storage_phase_code "$Phase" FailureCode || return 80
    verify_common_root_invariants "$FailureCode" || Status=$?
    (( Status == 80 )) && return 80
    (( Status == 0 )) || return "$FailureCode"
    run_private_probe "${StorageContext[CanonicalRoot]}" "$FailureCode" || Status=$?
    (( Status == 80 )) && return 80
    (( Status == 0 )) || return "$FailureCode"
    return 0
}

# Назначение: Проверяет owner/mode каталогов, созданных текущим запуском, прежде чем считать их безопасными.
verify_created_component_modes()
{
    local LogicalRoot="$1"
    local ExistingAncestor="$2"
    local Candidate="$LogicalRoot"
    local Parent=''
    local Type=''
    local Owner=''
    local Mode=''
    local Device=''
    local Inode=''
    local -a CreatedPaths=()

    while [[ "$Candidate" != "$ExistingAncestor" ]]; do
        CreatedPaths+=("$Candidate")
        path_parent "$Candidate" Parent
        [[ "$Parent" != "$Candidate" ]] || return 35
        Candidate="$Parent"
    done
    for Candidate in "${CreatedPaths[@]}"; do
        [[ -d "$Candidate" && ! -L "$Candidate" ]] || return 35
        stat_path_metadata "$Candidate" false Type Owner Mode Device Inode || return 35
        [[ "$Type" == directory && "$Mode" == 700 ]] || return 35
    done
    return 0
}

# Назначение: Квалифицирует и при необходимости создаёт BackupRoot, активирует network mount и сохраняет его identity.
prepare_backup_root()
{
    local Logical=''
    local Proposed=''
    local State=''
    local Ancestor=''
    local Canonical=''
    local Type=''
    local Owner=''
    local Mode=''
    local Device=''
    local Inode=''
    local FailureCode=63
    # Passed by name to same_mount_identity.
    # shellcheck disable=SC2034
    local -A QualifiedMount=()
    local -A FinalMount=()
    local -a MkdirCommand=()
    local -a RealpathCommand=()

    [[ "${LockContext[RootHeld]:-false}" == true ]] || return 80
    resolve_backup_root "${EffectiveConfig[BackupRoot]}" Logical Proposed State Ancestor || return $?
    if [[ "$Proposed" != "${StorageContext[ProposedRoot]}" ]]; then
        [[ "${ExecutionState[RunMode]}" == single ]] && return 33
        return 63
    fi
    StorageContext[LogicalRoot]="$Logical"
    StorageContext[ObjectState]="$State"
    StorageContext[ExistingAncestor]="$Ancestor"

    if [[ "${ExecutionState[RunMode]}" == batch && "${EffectiveConfig[UseNetFolder]}" == true ]]; then
        StorageContext[NetworkMode]=true
        activate_network_root "$Logical" || return 62
    else
        StorageContext[NetworkMode]=false
    fi

    if [[ "$State" == missing ]]; then
        MkdirCommand=(mkdir -p -m 0700 -- "$Logical")
        if ! "${MkdirCommand[@]}" 2>/dev/null; then
            if [[ "${ExecutionState[RunMode]}" == single ]]; then
                return 34
            elif [[ "${StorageContext[NetworkMode]}" == true ]]; then
                return 63
            fi
            return 61
        fi
        verify_created_component_modes "$Logical" "$Ancestor" || {
            [[ "${ExecutionState[RunMode]}" == single ]] && return 34
            return 63
        }
    fi

    RealpathCommand=(realpath -e -- "$Logical")
    Canonical="$("${RealpathCommand[@]}" 2>/dev/null)" || {
        [[ "${ExecutionState[RunMode]}" == single ]] && return 33
        return 63
    }
    if [[ "$Canonical" != "$Proposed" || "$Canonical" == / || ! -d "$Canonical" ]]; then
        [[ "${ExecutionState[RunMode]}" == single ]] && return 33
        return 63
    fi

    if [[ "${StorageContext[NetworkMode]}" == true ]]; then
        QualifiedMount[ID]="${StorageContext[QualifiedMountID]}"
        QualifiedMount[TARGET]="${StorageContext[QualifiedMountTARGET]}"
        QualifiedMount[SOURCE]="${StorageContext[QualifiedMountSOURCE]}"
        QualifiedMount[FSTYPE]="${StorageContext[QualifiedMountFSTYPE]}"
        [[ -n "${QualifiedMount[FSTYPE]}" ]] || return 62
        inspect_mount "$Canonical" FinalMount || return 62
        same_mount_identity QualifiedMount FinalMount || return 62
        StorageContext[MountID]="${FinalMount[ID]}"
        StorageContext[MountTARGET]="${FinalMount[TARGET]}"
        StorageContext[MountSOURCE]="${FinalMount[SOURCE]}"
        StorageContext[MountFSTYPE]="${FinalMount[FSTYPE]}"
    fi

    stat_path_metadata "$Canonical" true Type Owner Mode Device Inode || {
        [[ "${ExecutionState[RunMode]}" == single ]] && return 34
        return 63
    }
    [[ "$Type" == directory ]] || {
        [[ "${ExecutionState[RunMode]}" == single ]] && return 33
        return 63
    }
    StorageContext[CanonicalRoot]="$Canonical"
    StorageContext[RootDevice]="$Device"
    StorageContext[RootInode]="$Inode"
    if [[ "${ExecutionState[RunMode]}" == single ]]; then
        FailureCode=36
        probe_storage_root single_preflight || return $?
    else
        FailureCode=63
        probe_storage_root batch_preflight || return $?
    fi
    : "$FailureCode"
    StorageContext[Prepared]=true
    return 0
}

# Назначение: Оркестрирует подготовку lock runtime, BackupRoot и root-lock до обработки устройств.
prepare_storage_and_root_lock()
{
    local Logical=''
    local Proposed=''
    local State=''
    local Ancestor=''
    local RuntimeDirectory=''
    local LockMode='exclusive'

    StorageContext=()
    LockContext=()
    resolve_backup_root "${EffectiveConfig[BackupRoot]}" Logical Proposed State Ancestor || return $?
    StorageContext[LogicalRoot]="$Logical"
    StorageContext[ProposedRoot]="$Proposed"
    StorageContext[ObjectState]="$State"
    StorageContext[ExistingAncestor]="$Ancestor"
    select_lock_runtime RuntimeDirectory || return 80
    prepare_lock_runtime "$RuntimeDirectory" || return $?
    LockContext[RuntimeDirectory]="$RuntimeDirectory"
    if [[ "${ExecutionState[RunMode]}" == single ]]; then
        LockMode=shared
    elif [[ "${ExecutionState[RunMode]}" != batch ]]; then
        return 80
    fi
    acquire_root_lock "$LockMode" || return $?
    prepare_backup_root
}

# Назначение: Проверяет, что общий root и mount не изменились после первоначальной квалификации.
recheck_common_storage()
{
    [[ "${ExecutionState[RunMode]:-}" == batch &&
       "${LockContext[RootHeld]:-false}" == true &&
       "${LockContext[RootMode]:-}" == exclusive ]] || return 80
    probe_storage_root active
}

# Назначение: Выполняет отдельный read/write/remove probe уже внутри каталога конкретного устройства.
probe_device_directory()
{
    local DeviceDirectory="$1"

    run_private_probe "$DeviceDirectory" 64
}

# Назначение: Создаёт и квалифицирует каталог устройства под root/device locks, не продолжая batch после потери общего storage.
# shellcheck disable=SC2034  # DeviceDirectoryOut is a nameref output.
prepare_device_directory()
{
    local RequestedName="$1"
    local -n DeviceDirectoryOut="$2"
    local DeviceId=''
    local DeviceName=''
    local DeviceDirectory=''
    local Status=0
    local RecheckStatus=0
    local Type=''
    local Owner=''
    local Mode=''
    local Device=''
    local Inode=''
    local -a MkdirCommand=()

    DeviceDirectoryOut=''
    [[ "${ExecutionState[RunMode]:-}" == batch &&
       "${LockContext[RootHeld]:-false}" == true &&
       "${LockContext[RootMode]:-}" == exclusive &&
       "${StorageContext[Prepared]:-false}" == true ]] || return 80
    resolve_claimed_device_identity "$RequestedName" DeviceId DeviceName || return 80
    : "$DeviceId"
    DeviceDirectory="${StorageContext[CanonicalRoot]}/$DeviceName"

    if [[ -e "$DeviceDirectory" || -L "$DeviceDirectory" ]]; then
        [[ -d "$DeviceDirectory" && ! -L "$DeviceDirectory" ]] || Status=64
    else
        MkdirCommand=(mkdir -m 0700 -- "$DeviceDirectory")
        "${MkdirCommand[@]}" 2>/dev/null || Status=64
        if (( Status == 0 )); then
            stat_path_metadata "$DeviceDirectory" false Type Owner Mode Device Inode || Status=64
            [[ "$Type" == directory && "$Mode" == 700 ]] || Status=64
        fi
    fi
    if (( Status == 0 )); then
        probe_device_directory "$DeviceDirectory" || Status=$?
        (( Status == 80 )) && return 80
        (( Status == 0 )) || Status=64
    fi
    if (( Status != 0 )); then
        RecheckStatus=0
        recheck_common_storage || RecheckStatus=$?
        if (( RecheckStatus == 0 )); then
            StorageContext[StopBatch]=false
            return 64
        fi
        (( RecheckStatus == 80 )) && return 80
        StorageContext[StopBatch]=true
        return 65
    fi
    DeviceDirectoryOut="$DeviceDirectory"
    return 0
}

# ==============================================================================
# RouterOS driver contract, framing and result classification
# ==============================================================================

# Назначение: Задаёт неизменяемые команды, frame-маркеры и режимы RouterOS-драйвера для текущей версии.
init_mikrotik_driver()
{
    MikrotikDriver=()
    MikrotikDriver[Name]='mikrotik-routeros'
    MikrotikDriver[Version]='1'
    MikrotikDriver[DestinationAlias]='mikrotik-backup-target'
    MikrotikDriver[FrameActionBegin]='__MB2_ACTION_BEGIN__'
    MikrotikDriver[FrameActionOk]='__MB2_ACTION_OK__'
    MikrotikDriver[FrameActionError]='__MB2_ACTION_ERROR__'
    MikrotikDriver[FrameDataBegin]='__MB2_DATA_BEGIN__'
    MikrotikDriver[FrameDataEnd]='__MB2_DATA_END__'
    MikrotikDriver[CapabilityIdentity]=true
    MikrotikDriver[CapabilityTextExport]=true
    MikrotikDriver[CapabilityBinaryBackup]=true
    MikrotikDriver[CapabilityRemoteSize]=true
    MikrotikDriver[CapabilityRemoteRemove]=true
    MikrotikDriver[CapabilityLegacyScp]=true
    MikrotikDriver[CapabilityDnsCleanup]=true
    MikrotikDriver[CapabilityConsoleHistoryCleanup]=true
    MikrotikDriver[CapabilityBinaryEncryption]=true
    MikrotikDriver[CapabilityTextComparisonFilter]=false
    MikrotikDriver[ModeIdentity]=capture_text
    MikrotikDriver[ModeTextExport]=discard
    MikrotikDriver[ModeBinaryBackup]=discard
    MikrotikDriver[ModeRemoteSize]=capture_text
    MikrotikDriver[ModeRemoteRemove]=discard
    MikrotikDriver[ModeDnsCleanup]=discard
    MikrotikDriver[ModeConsoleHistoryCleanup]=discard
    MikrotikDriver[BinaryStaticProperties]='dont-encrypt=yes'
    return 0
}

# Назначение: Проверяет, что значение driver-переключателя строго равно true либо false.
driver_boolean_valid()
{
    [[ "$1" == true || "$1" == false ]]
}

# Назначение: Проверяет значение драйвера по переданному закрытому перечню допустимых режимов.
driver_mode_valid()
{
    case "$1" in
        capture_text|stream_file|discard) return 0 ;;
        *) return 81 ;;
    esac
}

# Назначение: Считает буквальные неперекрывающиеся появления строки для проверки уникальности frame-маркеров.
count_literal_occurrences()
{
    local Haystack="$1"
    local Needle="$2"
    local -n CountOut="$3"
    local Prefix=''

    CountOut=0
    [[ -n "$Needle" ]] || return 80
    while [[ "$Haystack" == *"$Needle"* ]]; do
        Prefix="${Haystack%%"$Needle"*}"
        Haystack="${Haystack:${#Prefix}+${#Needle}}"
        CountOut=$((CountOut + 1))
    done
    return 0
}

# Назначение: Проверяет полноту и взаимную согласованность таблицы драйвера до любого транспортного вызова.
validate_mikrotik_driver_contract()
{
    local Key
    local OtherKey
    local Capability
    local FunctionName
    local FunctionList
    local ModeKey
    local RequiredMode
    local Occurrences=0
    local LowerProperties=''
    local -a MandatoryCapabilities=(
        CapabilityIdentity CapabilityTextExport CapabilityBinaryBackup
        CapabilityRemoteSize CapabilityRemoteRemove CapabilityLegacyScp
    )
    local -a OptionalCapabilities=(
        CapabilityDnsCleanup CapabilityConsoleHistoryCleanup
        CapabilityBinaryEncryption CapabilityTextComparisonFilter
    )
    local -a RequiredFunctions=(
        routeros_quote_string build_common_transport_options
        build_ssh_argv execute_ssh_operation
    )
    local -a CapabilityFunctions=()
    local -a CapabilityRequirements=(
        'CapabilityIdentity|mikrotik_get_identity|ModeIdentity|capture_text'
        'CapabilityTextExport|mikrotik_create_text_export|ModeTextExport|discard'
        'CapabilityBinaryBackup|mikrotik_create_binary_backup|ModeBinaryBackup|discard'
        'CapabilityRemoteSize|mikrotik_get_remote_size|ModeRemoteSize|capture_text'
        'CapabilityRemoteRemove|mikrotik_remove_remote_result|ModeRemoteRemove|discard'
        'CapabilityLegacyScp|build_scp_argv,fetch_remote_file|-|-'
        'CapabilityDnsCleanup|mikrotik_flush_dns_cache|ModeDnsCleanup|discard'
        'CapabilityConsoleHistoryCleanup|mikrotik_clear_console_history|ModeConsoleHistoryCleanup|discard'
        'CapabilityTextComparisonFilter|mikrotik_filter_text_comparison|ModeTextComparisonFilter|capture_text'
    )

    [[ "${MikrotikDriver[Name]:-}" == mikrotik-routeros &&
       "${MikrotikDriver[Version]:-}" =~ ^[0-9]+$ &&
       "${MikrotikDriver[DestinationAlias]:-}" =~ ^[A-Za-z][A-Za-z0-9-]{0,62}$ ]] || return 81
    for Key in "${MandatoryCapabilities[@]}"; do
        [[ -n "${MikrotikDriver[$Key]+x}" ]] || return 81
        driver_boolean_valid "${MikrotikDriver[$Key]}" || return 81
        [[ "${MikrotikDriver[$Key]}" == true ]] || return 81
    done
    for Key in "${OptionalCapabilities[@]}"; do
        [[ -n "${MikrotikDriver[$Key]+x}" ]] || return 81
        driver_boolean_valid "${MikrotikDriver[$Key]}" || return 81
    done
    [[ -n "${MikrotikDriver[FrameActionBegin]:-}" &&
       -n "${MikrotikDriver[FrameActionOk]:-}" &&
       -n "${MikrotikDriver[FrameActionError]:-}" &&
       -n "${MikrotikDriver[FrameDataBegin]:-}" &&
       -n "${MikrotikDriver[FrameDataEnd]:-}" ]] || return 81
    for Key in FrameActionBegin FrameActionOk FrameActionError FrameDataBegin FrameDataEnd; do
        [[ "${MikrotikDriver[$Key]}" != *[$'\001'-$'\037'$'\177']* ]] || return 81
        for OtherKey in FrameActionBegin FrameActionOk FrameActionError FrameDataBegin FrameDataEnd; do
            [[ "$Key" == "$OtherKey" ]] && continue
            [[ "${MikrotikDriver[$Key]}" != "${MikrotikDriver[$OtherKey]}" ]] || return 81
        done
    done
    for FunctionName in "${RequiredFunctions[@]}"; do
        declare -F "$FunctionName" >/dev/null 2>&1 || return 81
    done
    for Key in "${CapabilityRequirements[@]}"; do
        IFS='|' read -r Capability FunctionList ModeKey RequiredMode <<< "$Key"
        [[ "${MikrotikDriver[$Capability]}" == true ]] || continue
        IFS=',' read -r -a CapabilityFunctions <<< "$FunctionList"
        for FunctionName in "${CapabilityFunctions[@]}"; do
            declare -F "$FunctionName" >/dev/null 2>&1 || return 81
        done
        if [[ "$ModeKey" != '-' ]]; then
            driver_mode_valid "${MikrotikDriver[$ModeKey]:-}" || return 81
            [[ "${MikrotikDriver[$ModeKey]}" == "$RequiredMode" ]] || return 81
        fi
    done
    LowerProperties="${MikrotikDriver[BinaryStaticProperties],,}"
    count_literal_occurrences "$LowerProperties" 'dont-encrypt=yes' Occurrences || return 81
    (( Occurrences == 1 )) || return 81
    [[ "$LowerProperties" != *'password='* && "$LowerProperties" != *'encryption='* ]] || return 81
    return 0
}

# Назначение: Проверяет адрес, пользователя, порт и password fd подготовленного DeviceContext.
validate_device_transport_context()
{
    local DeviceId="$1"
    local NumericPort=0

    device_context_exists "$DeviceId" || return 80
    local -n TransportDeviceContext="$DeviceId"
    [[ -n "${TransportDeviceContext[Address]:-}" &&
       -n "${TransportDeviceContext[User]:-}" &&
       -n "${TransportDeviceContext[Password]:-}" ]] || return 80
    [[ "${TransportDeviceContext[Port]:-}" =~ ^[1-9][0-9]*$ ]] || return 80
    NumericPort=$((10#${TransportDeviceContext[Port]}))
    (( NumericPort >= 1 && NumericPort <= 65535 )) || return 80
    [[ "$NumericPort" == "${TransportDeviceContext[Port]}" ]] || return 80
    [[ "${TransportDeviceContext[Address]}" != *[$'\001'-$'\037'$'\177']* &&
       "${TransportDeviceContext[User]}" != *[$'\001'-$'\037'$'\177']* ]] || return 80
    [[ "${TransportDeviceContext[Password]}" != *$'\r'* &&
       "${TransportDeviceContext[Password]}" != *$'\n'* ]] || return 80
    return 0
}

# Назначение: Формирует общий массив безопасных SSH/SCP options из driver policy и порта устройства.
# shellcheck disable=SC2034  # OptionsOut is a nameref output array.
build_common_transport_options()
{
    local DeviceId="$1"
    local -n OptionsOut="$2"

    validate_device_transport_context "$DeviceId" || return 80
    local -n CommonOptionDevice="$DeviceId"
    OptionsOut=(
        -F /dev/null
        -o "HostName=${CommonOptionDevice[Address]}"
        -o "User=${CommonOptionDevice[User]}"
        -o ConnectionAttempts=5
        -o ConnectTimeout=5
        -o ServerAliveInterval=15
        -o ServerAliveCountMax=2
        -o TCPKeepAlive=yes
        -o BatchMode=no
        -o 'PreferredAuthentications=keyboard-interactive,password'
        -o PubkeyAuthentication=no
        -o HostbasedAuthentication=no
        -o GSSAPIAuthentication=no
        -o PasswordAuthentication=yes
        -o KbdInteractiveAuthentication=yes
        -o NumberOfPasswordPrompts=1
        -o IdentityAgent=none
        -o IdentityFile=none
        -o StrictHostKeyChecking=no
        -o UserKnownHostsFile=/dev/null
        -o GlobalKnownHostsFile=/dev/null
        -o CheckHostIP=no
        -o UpdateHostKeys=no
        -o RequestTTY=no
        -o ForwardAgent=no
        -o ForwardX11=no
        -o ClearAllForwardings=yes
        -o ControlMaster=no
        -o ControlPath=none
        -o ControlPersist=no
        -o LogLevel=ERROR
    )
    return 0
}

# Назначение: Собирает argv ssh/sshpass с password fd и командой RouterOS без промежуточной shell-строки.
# shellcheck disable=SC2034  # ArgvOut is a nameref output array.
build_ssh_argv()
{
    local DeviceId="$1"
    local PasswordFd="$2"
    local RouterCommand="$3"
    local -n ArgvOut="$4"
    local -a CommonOptions=()

    [[ "$PasswordFd" =~ ^[0-9]+$ && -n "$RouterCommand" ]] || return 81
    build_common_transport_options "$DeviceId" CommonOptions || return $?
    local -n SshArgvDevice="$DeviceId"
    ArgvOut=(
        sshpass -d "$PasswordFd" ssh
        "${CommonOptions[@]}"
        -p "${SshArgvDevice[Port]}"
        -n -- "${MikrotikDriver[DestinationAlias]}" "$RouterCommand"
    )
    return 0
}

# Назначение: Собирает argv scp/sshpass для одного проверенного remote result и локального назначения.
# shellcheck disable=SC2034  # ArgvOut is a nameref output array.
build_scp_argv()
{
    local DeviceId="$1"
    local PasswordFd="$2"
    local RemoteName="$3"
    local LocalPath="$4"
    # ShellCheck cannot infer that the fifth argument names an output array.
    # shellcheck disable=SC2178
    local -n ArgvOut="$5"
    local -a CommonOptions=()

    [[ "$PasswordFd" =~ ^[0-9]+$ && -n "$LocalPath" ]] || return 81
    validate_remote_result_name "$RemoteName" || return $?
    build_common_transport_options "$DeviceId" CommonOptions || return $?
    local -n ScpArgvDevice="$DeviceId"
    ArgvOut=(
        sshpass -d "$PasswordFd" scp
        "${CommonOptions[@]}"
        -P "${ScpArgvDevice[Port]}" -O --
        "${MikrotikDriver[DestinationAlias]}:/$RemoteName" "$LocalPath"
    )
    return 0
}

# Назначение: Допускает только простое RouterOS-имя результата без разделителей пути и управляющих символов.
validate_remote_result_name()
{
    local RemoteName="$1"
    local LC_ALL=C

    [[ "$RemoteName" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,95}$ ]] || return 80
    return 0
}

# Назначение: Проверяет stem до добавления расширения и запрещает неоднозначные/служебные remote-имена.
validate_remote_creation_stem()
{
    local RemoteStem="$1"
    local LowerStem="${RemoteStem,,}"

    validate_remote_result_name "$RemoteStem" || return $?
    [[ "$LowerStem" != *.rsc && "$LowerStem" != *.backup ]] || return 80
    return 0
}

# Назначение: Кодирует строку в литерал RouterOS CLI, экранируя кавычки, обратные слэши и управляющие байты.
# shellcheck disable=SC2034  # QuotedOut is a nameref output.
routeros_quote_string()
{
    local Value="$1"
    local -n QuotedOut="$2"

    [[ "$Value" != *[$'\001'-$'\037'$'\177']* ]] || return 80
    Value="${Value//\\/\\\\}"
    Value="${Value//\$/\\\$}"
    Value="${Value//\"/\\\"}"
    QuotedOut="\"$Value\""
    return 0
}

# Назначение: Проверяет точную последовательность begin/ok frame для команды без data-результата.
# shellcheck disable=SC2034  # ParsedOut is a nameref output.
parse_routeros_action_frame()
{
    local Output="$1"
    local -n ParsedOut="$2"
    local NormalizedOutput=''
    local ActionBody=''
    local BeginCount=0
    local OkCount=0
    local ErrorCount=0

    ParsedOut=''
    normalize_routeros_frame_output "$Output" NormalizedOutput || return 42
    if [[ "$NormalizedOutput" == "${MikrotikDriver[FrameActionError]}" ||
          "$NormalizedOutput" == "${MikrotikDriver[FrameActionBegin]}"$'\n'"${MikrotikDriver[FrameActionError]}" ]]; then
        ParsedOut=remote_error
        return 42
    fi
    [[ "$NormalizedOutput" == "${MikrotikDriver[FrameActionBegin]}"$'\n'* ]] || return 42
    count_literal_occurrences "$NormalizedOutput" "${MikrotikDriver[FrameActionBegin]}" BeginCount || return 80
    count_literal_occurrences "$NormalizedOutput" "${MikrotikDriver[FrameActionOk]}" OkCount || return 80
    count_literal_occurrences "$NormalizedOutput" "${MikrotikDriver[FrameActionError]}" ErrorCount || return 80
    (( BeginCount == 1 && OkCount == 1 && ErrorCount == 0 )) || return 42

    ActionBody="${NormalizedOutput#"${MikrotikDriver[FrameActionBegin]}"$'\n'}"
    [[ "$ActionBody" == "${MikrotikDriver[FrameActionOk]}" ||
       "$ActionBody" == *$'\n'"${MikrotikDriver[FrameActionOk]}" ]] || return 42
    ParsedOut=success
    return 0
}

# Назначение: Нормализует только допустимые LF/CRLF окончания транспортного frame-вывода.
# RouterOS may use either LF or CRLF. Normalize only a complete, uniform CRLF
# stream; bare CR and mixed separators remain malformed. One terminal newline
# is framing, while any additional line remains visible to the strict parsers.
# shellcheck disable=SC2034  # NormalizedOut is a nameref output.
normalize_routeros_frame_output()
{
    local Output="$1"
    local -n NormalizedOut="$2"
    local Candidate=''
    local Reencoded=''

    NormalizedOut=''
    if [[ "$Output" == *$'\r'* ]]; then
        [[ "$Output" == *$'\r\n' ]] || return 42
        Candidate="${Output//$'\r\n'/$'\n'}"
        [[ "$Candidate" != *$'\r'* ]] || return 42
        Reencoded="${Candidate//$'\n'/$'\r\n'}"
        [[ "$Reencoded" == "$Output" ]] || return 42
    else
        Candidate="$Output"
    fi
    [[ "$Candidate" == *$'\n' ]] && Candidate="${Candidate%$'\n'}"
    NormalizedOut="$Candidate"
    return 0
}

# Назначение: Извлекает единственную data-строку между begin/end frame и отклоняет лишний вывод.
# shellcheck disable=SC2034  # DataOut is a nameref output.
parse_routeros_data_frame()
{
    local Output="$1"
    local -n DataOut="$2"
    local Prefix="${MikrotikDriver[FrameDataBegin]}"$'\n'
    local Suffix=$'\n'"${MikrotikDriver[FrameDataEnd]}"
    local NormalizedOutput=''
    local Value=''

    DataOut=''
    normalize_routeros_frame_output "$Output" NormalizedOutput || return 42
    [[ "$NormalizedOutput" == "$Prefix"*"$Suffix" ]] || return 42
    Value="${NormalizedOutput#"$Prefix"}"
    Value="${Value%"$Suffix"}"
    [[ -n "$Value" && "$Value" != *$'\n'* && "$Value" != *$'\r'* ]] || return 42
    DataOut="$Value"
    return 0
}

# Назначение: Распознаёт ограниченный набор диагностик SSH, достоверно указывающих на отказ аутентификации.
diagnostic_has_auth_evidence()
{
    local Diagnostic="${1,,}"

    [[ "$Diagnostic" == *'permission denied'* ||
       "$Diagnostic" == *'no supported authentication methods available'* ||
       "$Diagnostic" == *'authentication failed'* ||
       "$Diagnostic" == *'__mb_test_auth_failure__'* ]]
}

# Назначение: Отличает ошибку запуска sshpass от ошибки удалённого SSH-сеанса.
diagnostic_has_sshpass_runtime_evidence()
{
    local Diagnostic="${1,,}"

    [[ "$Diagnostic" == *'sshpass:'* || "$Diagnostic" == *'sshpass '* ]]
}

# Назначение: Сопоставляет exit/diagnostic SSH контрактным кодам auth, timeout, transport или protocol.
# shellcheck disable=SC2034  # CodeOut is a nameref output.
classify_ssh_transport_result()
{
    local RawStatus="$1"
    local Diagnostic="$2"
    local -n CodeOut="$3"

    [[ "$RawStatus" =~ ^[0-9]+$ ]] || return 80
    if (( RawStatus == 0 )); then
        CodeOut=0
    elif (( RawStatus == 255 )) && diagnostic_has_auth_evidence "$Diagnostic"; then
        CodeOut=41
    elif (( RawStatus == 255 )) || diagnostic_has_sshpass_runtime_evidence "$Diagnostic"; then
        CodeOut=40
    elif (( RawStatus == 124 || RawStatus == 137 || RawStatus == 126 || RawStatus == 127 )); then
        CodeOut=40
    else
        CodeOut=42
    fi
    return 0
}

# Назначение: Сопоставляет exit/diagnostic SCP контрактным кодам fetch, auth, timeout либо transport.
# shellcheck disable=SC2034  # CodeOut is a nameref output.
classify_scp_transport_result()
{
    local RawStatus="$1"
    local Diagnostic="$2"
    local -n CodeOut="$3"

    [[ "$RawStatus" =~ ^[0-9]+$ ]] || return 80
    if (( RawStatus == 0 )); then
        CodeOut=0
    elif (( RawStatus == 255 )) && diagnostic_has_auth_evidence "$Diagnostic"; then
        CodeOut=41
    elif (( RawStatus == 255 || RawStatus == 124 || RawStatus == 137 || RawStatus == 126 || RawStatus == 127 )) ||
         diagnostic_has_sshpass_runtime_evidence "$Diagnostic"; then
        CodeOut=40
    else
        CodeOut=43
    fi
    return 0
}

# ==============================================================================
# SSH/SCP execution and local capability probes
# ==============================================================================

# Назначение: Строит минимальные options для локальных capability-probes без сетевого подключения.
build_transport_probe_options()
{
    local -n ProbeOptionsOut="$1"

    # Output is observed through the caller-provided array nameref.
    # shellcheck disable=SC2034
    ProbeOptionsOut=(
        -F /dev/null
        -o HostName=127.0.0.1
        -o User=mikrotik-probe
        -o ConnectionAttempts=5
        -o ConnectTimeout=5
        -o ServerAliveInterval=15
        -o ServerAliveCountMax=2
        -o TCPKeepAlive=yes
        -o BatchMode=no
        -o 'PreferredAuthentications=keyboard-interactive,password'
        -o PubkeyAuthentication=no
        -o HostbasedAuthentication=no
        -o GSSAPIAuthentication=no
        -o PasswordAuthentication=yes
        -o KbdInteractiveAuthentication=yes
        -o NumberOfPasswordPrompts=1
        -o IdentityAgent=none
        -o IdentityFile=none
        -o StrictHostKeyChecking=no
        -o UserKnownHostsFile=/dev/null
        -o GlobalKnownHostsFile=/dev/null
        -o CheckHostIP=no
        -o UpdateHostKeys=no
        -o RequestTTY=no
        -o ForwardAgent=no
        -o ForwardX11=no
        -o ClearAllForwardings=yes
        -o ControlMaster=no
        -o ControlPath=none
        -o ControlPersist=no
        -o LogLevel=ERROR
    )
    return 0
}

# Назначение: Проверяет, что установленный ssh принимает обязательные client options.
check_ssh_parser_capability()
{
    local Status=0
    local -a ProbeOptions=()
    local -a ProbeCommand=()

    build_transport_probe_options ProbeOptions
    ProbeCommand=(ssh "${ProbeOptions[@]}" -p 22 -G -- "${MikrotikDriver[DestinationAlias]}")
    LC_ALL=C "${ProbeCommand[@]}" >/dev/null 2>&1 || Status=$?
    (( Status == 0 )) || return 30
    return 0
}

# Назначение: Проверяет поддержку требуемого legacy SCP режима и отличает parser failure от сетевого.
check_scp_legacy_capability()
{
    local Status=0
    local Diagnostic=''
    local -a ProbeOptions=()
    local -a ProbeCommand=()

    build_transport_probe_options ProbeOptions
    ProbeCommand=(scp "${ProbeOptions[@]}" -P 22 -O)
    Diagnostic="$(LC_ALL=C "${ProbeCommand[@]}" 2>&1)" || Status=$?
    if (( Status == 0 )); then
        return 0
    fi
    Diagnostic="${Diagnostic,,}"
    [[ "$Diagnostic" != *'unknown option'* &&
       "$Diagnostic" != *'illegal option'* &&
       "$Diagnostic" != *'bad configuration option'* ]] || return 30
    [[ "$Diagnostic" == *'usage:'* ]] || return 30
    return 0
}

# Назначение: Проверяет наличие GNU timeout с нужными signal/kill-after возможностями.
check_timeout_capability()
{
    local Status=0
    local -a SuccessProbe=(timeout --signal=TERM --kill-after=1s 1s /bin/true)
    local -a StatusProbe=(timeout --signal=TERM --kill-after=1s 1s /bin/false)

    LC_ALL=C "${SuccessProbe[@]}" >/dev/null 2>&1 || return 30
    LC_ALL=C "${StatusProbe[@]}" >/dev/null 2>&1 || Status=$?
    (( Status == 1 )) || return 30
    return 0
}

# Назначение: Последовательно выполняет локальные probes ssh, scp и timeout до обработки устройств.
check_transport_client_capabilities()
{
    check_ssh_parser_capability || return 30
    check_scp_legacy_capability || return 30
    check_timeout_capability || return 30
    return 0
}

# Назначение: Добавляет этап к детерминированной транспортной трассе для тестов и диагностики.
append_transport_trace()
{
    local Event="$1"

    RuntimeState[TransportTrace]+="${RuntimeState[TransportTrace]:+ }$Event"
    if [[ -n "${RuntimeState[TransportTracePath]:-}" ]]; then
        printf '%s\n' "$Event" >> "${RuntimeState[TransportTracePath]}" 2>/dev/null || :
    fi
    return 0
}

# Назначение: Создаёт приватный pipe, записывает login password и регистрирует читающий fd для sshpass.
# shellcheck disable=SC2034  # Descriptor outputs use namerefs.
open_password_channel()
{
    local Password="$1"
    local -n PasswordFdOut="$2"
    local -n CleanupIdOut="$3"
    local OpenedFd=0
    local CleanupEntryId=''

    PasswordFdOut=''
    CleanupIdOut=''
    [[ -n "$Password" && "$Password" != *$'\r'* && "$Password" != *$'\n'* ]] || return 80
    exec {OpenedFd}< <(printf '%s\n' "$Password") || return 40
    register_cleanup_fd "$OpenedFd" CleanupEntryId || {
        exec {OpenedFd}<&-
        return 80
    }
    RuntimeState[PasswordChannelFd]="$OpenedFd"
    PasswordFdOut="$OpenedFd"
    CleanupIdOut="$CleanupEntryId"
    append_transport_trace password_open
    return 0
}

# Назначение: Закрывает один зарегистрированный descriptor и гарантированно снимает cleanup entry.
close_registered_fd()
{
    local Descriptor="$1"
    local CleanupEntryId="$2"

    [[ "$Descriptor" =~ ^[0-9]+$ ]] || return 80
    exec {Descriptor}>&-
    unregister_cleanup_entry "$CleanupEntryId" || return 80
    append_transport_trace fd_close
    return 0
}

# Назначение: Закрывает активный password fd и очищает ссылку на него в DeviceContext/runtime.
close_password_channel()
{
    local Descriptor="$1"
    local CleanupEntryId="$2"
    local Status=0

    close_registered_fd "$Descriptor" "$CleanupEntryId" || Status=$?
    if [[ "${RuntimeState[PasswordChannelFd]:-}" == "$Descriptor" ]]; then
        RuntimeState[PasswordChannelFd]=''
    fi
    append_transport_trace password_close
    return "$Status"
}

# Назначение: Создаёт и регистрирует приватный capture-файл для stdout/stderr дочернего транспорта.
# shellcheck disable=SC2034  # Path and cleanup outputs use namerefs.
create_private_transport_file()
{
    local Purpose="$1"
    local -n CapturePathOut="$2"
    local -n CaptureCleanupOut="$3"
    local RuntimeDirectory="${LockContext[RuntimeDirectory]:-}"
    local Candidate=''
    local EntryId=''
    local Attempt
    local Type=''
    local Owner=''
    local Mode=''
    local Device=''
    local Inode=''

    CapturePathOut=''
    CaptureCleanupOut=''
    if [[ -z "$RuntimeDirectory" ]]; then
        select_lock_runtime RuntimeDirectory || return 80
        prepare_lock_runtime "$RuntimeDirectory" || return 40
    fi
    for ((Attempt=0; Attempt<100; Attempt++)); do
        Candidate="$RuntimeDirectory/.transport.${Purpose}.${BASHPID}.${RANDOM}.${Attempt}"
        if attempt_noclobber_redirection "$Candidate"; then
            # Registration failure exposes no identity proof; preserve the current pathname.
            register_cleanup_path "$Candidate" || return 80
            stat_path_metadata "$Candidate" false Type Owner Mode Device Inode || return 40
            [[ "$Type" == regular*file && "$Owner" == "$UID" && "$Mode" == 600 ]] || return 40
            for EntryId in "${CleanupRegistry[@]}"; do
                local -n CandidateCleanupEntry="$EntryId"
                if [[ "${CandidateCleanupEntry[Active]:-false}" == true &&
                      "${CandidateCleanupEntry[Value]:-}" == "$Candidate" ]]; then
                    CaptureCleanupOut="$EntryId"
                    break
                fi
            done
            [[ -n "$CaptureCleanupOut" ]] || return 80
            CapturePathOut="$Candidate"
            return 0
        fi
    done
    return 40
}

# Назначение: Удаляет только принадлежащий transport capture после проверки сохранённого identity.
remove_private_transport_file()
{
    local CapturePath="$1"
    local CleanupEntryId="$2"
    local -n CaptureCleanupEntry="$CleanupEntryId"

    [[ "${CaptureCleanupEntry[Active]:-false}" == true &&
       "${CaptureCleanupEntry[Type]:-}" == file &&
       "${CaptureCleanupEntry[Value]:-}" == "$CapturePath" ]] || return 80
    cleanup_entry_matches_path "$CleanupEntryId" || return 40
    rm -f -- "$CapturePath" 2>/dev/null || return 40
    unregister_cleanup_entry "$CleanupEntryId" || return 80
    return 0
}

# Назначение: Открывает проверенный capture path на запись и возвращает descriptor без подмены цели.
# shellcheck disable=SC2034  # Descriptor outputs use namerefs.
open_transport_output_fd()
{
    local Path="$1"
    local -n DescriptorOut="$2"
    local -n CleanupIdOut="$3"
    local Descriptor=0
    local CleanupEntryId=''

    DescriptorOut=''
    CleanupIdOut=''
    exec {Descriptor}> "$Path" || return 40
    register_cleanup_fd "$Descriptor" CleanupEntryId || {
        exec {Descriptor}>&-
        return 80
    }
    DescriptorOut="$Descriptor"
    CleanupIdOut="$CleanupEntryId"
    return 0
}

# Назначение: В дочернем процессе закрывает все служебные fd, кроме явно разрешённых транспорту.
close_transport_child_inherited_fds()
{
    local PasswordFd="$1"
    local EntryId
    local Declaration=''
    local InheritedFd=0

    [[ "$PasswordFd" =~ ^[0-9]+$ ]] || return 80
    for EntryId in "${CleanupRegistry[@]}"; do
        Declaration="$(declare -p "$EntryId" 2>/dev/null)" || continue
        [[ "$Declaration" == "declare -A $EntryId="* ]] || continue
        local -n InheritedCleanupEntry="$EntryId"
        [[ "${InheritedCleanupEntry[Active]:-false}" == true &&
           "${InheritedCleanupEntry[Type]:-}" == fd ]] || continue
        InheritedFd="${InheritedCleanupEntry[Value]}"
        [[ "$InheritedFd" =~ ^[0-9]+$ ]] || return 80
        [[ "$InheritedFd" == "$PasswordFd" ]] && continue
        exec {InheritedFd}>&- || return 80
    done
    return 0
}

# Назначение: Запускает transport argv под единым timeout, направляя вывод в подготовленные capture descriptors.
transport_child_exec()
{
    local ArgvName="$1"
    local PasswordFd="$2"
    local -n ChildExecArgv="$ArgvName"

    close_transport_child_inherited_fds "$PasswordFd" || return 127
    export LC_ALL=C
    exec timeout --signal=TERM --kill-after=5s 300s "${ChildExecArgv[@]}"
}

# Назначение: Запускает transport_child_exec в фоне и под отсрочкой сигналов фиксирует PID и владение прямым дочерним процессом; PGID не сохраняет.
# shellcheck disable=SC2034  # ChildPidOut is a nameref output.
launch_transport_child()
{
    local ArgvName="$1"
    local OutputFd="$2"
    local DiagnosticFd="$3"
    local -n ChildPidOut="$4"
    local -n LaunchArgv="$ArgvName"
    local SpawnedPid=0
    local DeferralStatus=0
    local PasswordFd="${RuntimeState[PasswordChannelFd]:-}"

    ChildPidOut=''
    [[ "${RuntimeState[ActiveTransportOwned]:-false}" == false &&
       "$OutputFd" =~ ^[0-9]+$ && "$DiagnosticFd" =~ ^[0-9]+$ &&
       "$PasswordFd" =~ ^[0-9]+$ &&
       ${#LaunchArgv[@]} -gt 0 ]] || return 80
    begin_signal_deferral || return 80
    transport_child_exec "$ArgvName" "$PasswordFd" \
        < /dev/null 1>&"$OutputFd" 2>&"$DiagnosticFd" &
    SpawnedPid=$!
    if [[ ! "$SpawnedPid" =~ ^[1-9][0-9]*$ ]]; then
        end_signal_deferral || :
        return 40
    fi
    RuntimeState[ActiveTransportPid]="$SpawnedPid"
    RuntimeState[ActiveTransportPgid]=''
    RuntimeState[ActiveTransportWaitable]=true
    RuntimeState[ActiveTransportOwned]=true
    append_transport_trace child_spawned
    ChildPidOut="$SpawnedPid"
    append_transport_trace timeout_child_owned
    append_transport_trace child_owned
    end_signal_deferral || DeferralStatus=$?
    (( DeferralStatus == 0 )) || return "$DeferralStatus"
    return 0
}

# Назначение: Сбрасывает PID/PGID и флаги владения после полного reap дочернего транспорта.
clear_active_transport_ownership()
{
    RuntimeState[ActiveTransportOwned]=false
    RuntimeState[ActiveTransportWaitable]=false
    RuntimeState[ActiveTransportPid]=''
    RuntimeState[ActiveTransportPgid]=''
    append_transport_trace ownership_clear
    return 0
}

# Назначение: Ожидает принадлежащий transport PID, сохраняет его exit и очищает active ownership.
# shellcheck disable=SC2034  # RawStatusOut is a nameref output.
wait_transport_child()
{
    local ChildPid="$1"
    local -n RawStatusOut="$2"
    local ObservedStatus=0

    [[ "${RuntimeState[ActiveTransportOwned]:-false}" == true &&
       "${RuntimeState[ActiveTransportWaitable]:-false}" == true &&
       "${RuntimeState[ActiveTransportPid]:-}" == "$ChildPid" ]] || return 80
    wait "$ChildPid" || ObservedStatus=$?
    append_transport_trace child_waited
    clear_active_transport_ownership
    RawStatusOut="$ObservedStatus"
    return 0
}

# Назначение: Посылает TERM принадлежащему прямому дочернему PID, при необходимости KILL, затем выполняет wait и сбрасывает владение; управление транспортной командой выполняет GNU timeout.
terminate_active_transport_child()
{
    local ChildPid="${RuntimeState[ActiveTransportPid]:-}"
    local Attempt

    [[ "${RuntimeState[ActiveTransportOwned]:-false}" == true ]] || return 0
    [[ "${RuntimeState[ActiveTransportWaitable]:-false}" == true &&
       "$ChildPid" =~ ^[1-9][0-9]*$ ]] || return 80
    append_transport_trace child_terminate
    kill -TERM -- "$ChildPid" 2>/dev/null || :
    for ((Attempt=0; Attempt<20; Attempt++)); do
        kill -0 -- "$ChildPid" 2>/dev/null || break
        sleep 0.05
    done
    if kill -0 -- "$ChildPid" 2>/dev/null; then
        append_transport_trace child_kill
        kill -KILL -- "$ChildPid" 2>/dev/null || :
    fi
    wait "$ChildPid" 2>/dev/null || :
    append_transport_trace child_waited
    clear_active_transport_ownership
    return 0
}

# Назначение: Заменяет все буквальные появления непустого секрета маркером без regexp-интерпретации.
replace_literal_with_redaction()
{
    local TextValue="$1"
    local SensitiveValue="$2"
    local -n RedactedOut="$3"
    local Prefix=''
    local Result=''

    if [[ -z "$SensitiveValue" ]]; then
        RedactedOut="$TextValue"
        return 0
    fi
    while [[ "$TextValue" == *"$SensitiveValue"* ]]; do
        Prefix="${TextValue%%"$SensitiveValue"*}"
        Result+="${Prefix}[REDACTED]"
        TextValue="${TextValue:${#Prefix}+${#SensitiveValue}}"
    done
    # Output is observed through the caller-provided nameref.
    # shellcheck disable=SC2034
    RedactedOut="$Result$TextValue"
    return 0
}

# Назначение: Ограничивает размер диагностического текста и редактирует известные login/user/address/additional secrets.
# shellcheck disable=SC2034  # SanitizedOut is a nameref output.
sanitize_transport_diagnostic()
{
    local Diagnostic="$1"
    local Password="$2"
    local User="$3"
    local Address="$4"
    local -n SanitizedOut="$5"
    local AdditionalSecret="${6:-}"
    local Character
    local WorkText=''
    local Index
    local LC_ALL=C
    local SensitiveValue
    local LongestValue=''
    local -a SensitiveValues=("$Password" "$User" "$Address" "$AdditionalSecret")

    while (( ${#SensitiveValues[@]} > 0 )); do
        LongestValue=''
        for SensitiveValue in "${SensitiveValues[@]}"; do
            if (( ${#SensitiveValue} > ${#LongestValue} )); then
                LongestValue="$SensitiveValue"
            fi
        done
        if [[ -n "$LongestValue" ]]; then
            replace_literal_with_redaction "$Diagnostic" "$LongestValue" Diagnostic
        fi
        local -a RemainingSensitiveValues=()
        for SensitiveValue in "${SensitiveValues[@]}"; do
            [[ "$SensitiveValue" == "$LongestValue" ]] ||
                RemainingSensitiveValues+=("$SensitiveValue")
        done
        SensitiveValues=("${RemainingSensitiveValues[@]}")
    done
    for ((Index=0; Index<${#Diagnostic}; Index++)); do
        Character="${Diagnostic:Index:1}"
        if [[ "$Character" == [[:cntrl:]] || "$Character" == [[:space:]] ]]; then
            WorkText+=' '
        else
            WorkText+="$Character"
        fi
    done
    while [[ "$WorkText" == *'  '* ]]; do
        WorkText="${WorkText//  / }"
    done
    WorkText="${WorkText# }"
    WorkText="${WorkText% }"
    SanitizedOut="${WorkText:0:4096}"
    return 0
}

# Назначение: Читает не больше лимита байт capture-файла и сообщает, был ли исходный вывод усечён.
# shellcheck disable=SC2034  # Chunk and EOF state are nameref outputs.
read_transport_capture_chunk()
{
    local CaptureReadFd="$1"
    local -n CaptureChunkOut="$2"
    local -n CaptureEofOut="$3"

    CaptureChunkOut=''
    CaptureEofOut=false
    if ! IFS= read -r -N 1024 CaptureChunkOut <&"$CaptureReadFd"; then
        CaptureEofOut=true
    fi
    return 0
}

# Назначение: Читает stderr capture, санитизирует известные секреты и сохраняет признаки происхождения/усечения.
# Redaction is resolved before a character can enter the retained window. The
# pending prefix grows only to the longest accepted sensitive value.
# shellcheck disable=SC2034  # DiagnosticOut is a nameref output.
read_sanitized_bounded_diagnostic()
{
    local Path="$1"
    local Password="$2"
    local User="$3"
    local Address="$4"
    local -n DiagnosticOut="$5"
    local AdditionalSecret="${6:-}"
    local CaptureReadFd=0
    local Chunk=''
    local PendingRaw=''
    local RetainedDiagnostic=''
    local FullMatch=''
    local SensitiveValue
    local Character=''
    local EndOfFile=false
    local NeedsMore=false
    local LastWasSpace=false
    local LC_ALL=C
    local -a SensitiveValues=("$Password" "$User" "$Address" "$AdditionalSecret")

    DiagnosticOut=''
    exec {CaptureReadFd}< "$Path" || return 40
    while (( ${#RetainedDiagnostic} < 4096 )); do
        if [[ -z "$PendingRaw" && "$EndOfFile" == false ]]; then
            read_transport_capture_chunk "$CaptureReadFd" Chunk EndOfFile || {
                exec {CaptureReadFd}<&-
                return 40
            }
            PendingRaw+="$Chunk"
        fi
        [[ -n "$PendingRaw" ]] || break

        FullMatch=''
        NeedsMore=false
        for SensitiveValue in "${SensitiveValues[@]}"; do
            [[ -n "$SensitiveValue" ]] || continue
            if [[ "$PendingRaw" == "$SensitiveValue"* ]]; then
                if (( ${#SensitiveValue} > ${#FullMatch} )); then
                    FullMatch="$SensitiveValue"
                fi
            elif [[ "$SensitiveValue" == "$PendingRaw"* ]]; then
                NeedsMore=true
            fi
        done
        if [[ "$NeedsMore" == true && "$EndOfFile" == false ]]; then
            read_transport_capture_chunk "$CaptureReadFd" Chunk EndOfFile || {
                exec {CaptureReadFd}<&-
                return 40
            }
            PendingRaw+="$Chunk"
            continue
        fi
        if [[ -n "$FullMatch" ]]; then
            RetainedDiagnostic+='[REDACTED]'
            LastWasSpace=false
            PendingRaw="${PendingRaw:${#FullMatch}}"
            continue
        fi

        Character="${PendingRaw:0:1}"
        PendingRaw="${PendingRaw:1}"
        if [[ "$Character" == [[:cntrl:]] || "$Character" == [[:space:]] ]]; then
            if [[ -n "$RetainedDiagnostic" && "$LastWasSpace" == false ]]; then
                RetainedDiagnostic+=' '
                LastWasSpace=true
            fi
        else
            RetainedDiagnostic+="$Character"
            LastWasSpace=false
        fi
    done
    exec {CaptureReadFd}<&-
    if [[ "$EndOfFile" == true && -z "$PendingRaw" ]]; then
        RetainedDiagnostic="${RetainedDiagnostic% }"
    fi
    DiagnosticOut="${RetainedDiagnostic:0:4096}"
    return 0
}

# Назначение: Читает stdout capture в пределах лимита для последующей frame-проверки.
read_bounded_operation_output()
{
    local Path="$1"
    local -n OperationOutputOut="$2"
    local Size=''
    local LC_ALL=C

    Size="$(stat -Lc '%s' -- "$Path" 2>/dev/null)" || return 40
    [[ "$Size" =~ ^[0-9]+$ ]] || return 40
    (( Size <= 65536 )) || return 42
    OperationOutputOut=''
    if (( Size > 0 )); then
        IFS= read -r -N "$Size" OperationOutputOut < "$Path" || return 40
        (( ${#OperationOutputOut} == Size )) || return 40
    fi
    return 0
}

# Назначение: Удаляет capture через ownership-aware primitive и сохраняет более ранний код операции.
remove_transport_capture_file()
{
    remove_private_transport_file "$1" "$2"
}

# Назначение: Выбирает итоговый код transport/capture/cleanup так, чтобы инфраструктурная ошибка не потерялась.
# Child classification wins once established. On child success, diagnostic or
# cleanup failure is a local transport failure, while unavailable SSH operation
# output is a remote/output-contract failure.
# shellcheck disable=SC2034  # FinalCodeOut is a nameref output.
select_transport_capture_result()
{
    local Protocol="$1"
    local ChildCode="$2"
    local DiagnosticReadStatus="$3"
    local OutputReadStatus="$4"
    local DiagnosticRemoveStatus="$5"
    local OutputRemoveStatus="$6"
    local -n FinalCodeOut="$7"

    [[ "$Protocol" == ssh || "$Protocol" == scp ]] || return 80
    [[ "$ChildCode" =~ ^(0|40|41|42|43)$ ]] || return 80
    if (( ChildCode != 0 )); then
        FinalCodeOut="$ChildCode"
    elif (( DiagnosticReadStatus != 0 || DiagnosticRemoveStatus != 0 || OutputRemoveStatus != 0 )); then
        FinalCodeOut=40
    elif (( OutputReadStatus != 0 )); then
        if [[ "$Protocol" == ssh ]]; then
            FinalCodeOut=42
        else
            FinalCodeOut=43
        fi
    else
        FinalCodeOut=0
    fi
    return 0
}

# Назначение: Проверяет, ожидает ли операция action-frame, data-frame или отсутствие framed stdout.
validate_operation_output_mode()
{
    local Operation="$1"
    local Mode="$2"

    driver_mode_valid "$Mode" || return 81
    case "$Operation:$Mode" in
        identity:capture_text|remote_size:capture_text|\
        text_export:discard|binary_backup:discard|remote_remove:discard|\
        dns_cleanup:discard|console_history_cleanup:discard|\
        text_export_stream:stream_file) return 0 ;;
        *) return 81 ;;
    esac
}

# Назначение: Выполняет один SSH-вызов с password channel, captures, timeout, frame parsing и безопасной классификацией результата.
# shellcheck disable=SC2034  # Optional operation data is a nameref output.
execute_ssh_operation()
{
    local DeviceId="$1"
    local Operation="$2"
    local OutputMode="$3"
    local RouterCommand="$4"
    local StreamPath="${5:-}"
    local DataOutName="${6:-}"
    local OutputPath=''
    local OutputPathCleanup=''
    local DiagnosticPath=''
    local DiagnosticPathCleanup=''
    local OutputFd=''
    local OutputFdCleanup=''
    local DiagnosticFd=''
    local DiagnosticFdCleanup=''
    local PasswordFd=''
    local PasswordFdCleanup=''
    local ChildPid=''
    local RawStatus=0
    local ProjectCode=0
    local FinalCode=0
    local Status=0
    local SanitizedDiagnostic=''
    local OperationOutput=''
    local LegacyOperationOutput=''
    local DiagnosticReadStatus=0
    local OutputReadStatus=0
    local DiagnosticRemoveStatus=0
    local OutputRemoveStatus=0
    local -a TransportArgv=()

    validate_operation_output_mode "$Operation" "$OutputMode" || return 81
    validate_device_transport_context "$DeviceId" || return 80
    local -n ExecutionDeviceContext="$DeviceId"
    if [[ "$OutputMode" == capture_text ]]; then
        [[ "$DataOutName" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 81
        local -n OperationDataOut="$DataOutName"
        OperationDataOut=''
    elif [[ "$OutputMode" == stream_file ]]; then
        [[ -n "$StreamPath" ]] || return 81
    fi

    TransportDiagnostic=()
    create_private_transport_file diagnostic DiagnosticPath DiagnosticPathCleanup || return $?
    if [[ "$OutputMode" == stream_file ]]; then
        OutputPath="$StreamPath"
    else
        create_private_transport_file output OutputPath OutputPathCleanup || {
            Status=$?
            remove_private_transport_file "$DiagnosticPath" "$DiagnosticPathCleanup" || :
            return "$Status"
        }
    fi
    open_transport_output_fd "$OutputPath" OutputFd OutputFdCleanup || Status=$?
    if (( Status == 0 )); then
        open_transport_output_fd "$DiagnosticPath" DiagnosticFd DiagnosticFdCleanup || Status=$?
    fi
    if (( Status == 0 )); then
        open_password_channel "${ExecutionDeviceContext[Password]}" PasswordFd PasswordFdCleanup || Status=$?
    fi
    if (( Status == 0 )); then
        build_ssh_argv "$DeviceId" "$PasswordFd" "$RouterCommand" TransportArgv || Status=$?
    fi
    if (( Status == 0 )); then
        launch_transport_child TransportArgv "$OutputFd" "$DiagnosticFd" ChildPid || Status=$?
    fi
    if (( Status != 0 )); then
        if [[ -n "$PasswordFd" ]]; then close_password_channel "$PasswordFd" "$PasswordFdCleanup" || :; fi
        if [[ -n "$DiagnosticFd" ]]; then close_registered_fd "$DiagnosticFd" "$DiagnosticFdCleanup" || :; fi
        if [[ -n "$OutputFd" ]]; then close_registered_fd "$OutputFd" "$OutputFdCleanup" || :; fi
        if [[ -n "$OutputPathCleanup" ]]; then remove_private_transport_file "$OutputPath" "$OutputPathCleanup" || :; fi
        remove_private_transport_file "$DiagnosticPath" "$DiagnosticPathCleanup" || :
        (( Status == 80 || Status == 81 )) && return "$Status"
        return 40
    fi

    wait_transport_child "$ChildPid" RawStatus || Status=$?
    close_password_channel "$PasswordFd" "$PasswordFdCleanup" || Status=80
    close_registered_fd "$DiagnosticFd" "$DiagnosticFdCleanup" || Status=80
    close_registered_fd "$OutputFd" "$OutputFdCleanup" || Status=80
    (( Status == 0 )) || return "$Status"

    read_sanitized_bounded_diagnostic "$DiagnosticPath" \
        "${ExecutionDeviceContext[Password]}" "${ExecutionDeviceContext[User]}" \
        "${ExecutionDeviceContext[Address]}" SanitizedDiagnostic \
        "${EffectiveConfig[encrypt]:-}" || DiagnosticReadStatus=$?
    if (( DiagnosticReadStatus == 0 )); then
        classify_ssh_transport_result "$RawStatus" "$SanitizedDiagnostic" ProjectCode || return 80
    else
        ProjectCode=40
    fi
    if [[ "$OutputMode" != stream_file ]]; then
        read_bounded_operation_output "$OutputPath" OperationOutput || OutputReadStatus=$?
    fi
    remove_transport_capture_file "$DiagnosticPath" "$DiagnosticPathCleanup" || DiagnosticRemoveStatus=$?
    if [[ -n "$OutputPathCleanup" ]]; then
        remove_transport_capture_file "$OutputPath" "$OutputPathCleanup" || OutputRemoveStatus=$?
    fi
    select_transport_capture_result ssh "$ProjectCode" \
        "$DiagnosticReadStatus" "$OutputReadStatus" \
        "$DiagnosticRemoveStatus" "$OutputRemoveStatus" FinalCode || return 80
    TransportDiagnostic[Operation]="$Operation"
    TransportDiagnostic[RawStatus]="$RawStatus"
    TransportDiagnostic[ProjectCode]="$FinalCode"
    TransportDiagnostic[Text]="$SanitizedDiagnostic"
    if (( FinalCode != 0 )); then
        return "$FinalCode"
    fi
    if [[ "$OutputMode" == capture_text ]]; then
        local -n CapturedOperationData="$DataOutName"
        CapturedOperationData="$OperationOutput"
    elif [[ "$OutputMode" == discard ]]; then
        TransportDiagnostic[FramedOperationOutput]="$OperationOutput"
        LegacyOperationOutput="$OperationOutput"
        while [[ "$LegacyOperationOutput" == *$'\n' ]]; do
            LegacyOperationOutput="${LegacyOperationOutput%$'\n'}"
        done
        TransportDiagnostic[OperationOutput]="$LegacyOperationOutput"
    fi
    return 0
}

# Назначение: Проверяет возможность эксклюзивно создать локальное назначение до запуска SCP.
# Private boolean probe used only after an SCP code 43 when the TASK-006 caller
# explicitly requests provenance.  The failed artifact is already cleanup-owned,
# so a successful one-byte append is harmless and the whole object is removed by
# the failed-attempt path.  Return 0 means local writing was positively available;
# return 1 means a local destination object/open/write/close failure was observed.
probe_fetch_destination_write()
{
    local LocalPath="$1"
    local ProbeFd=0
    local Status=0

    if [[ -e "$LocalPath" || -L "$LocalPath" ]]; then
        [[ -f "$LocalPath" && ! -L "$LocalPath" ]] || return 1
    fi
    { exec {ProbeFd}>> "$LocalPath"; } 2>/dev/null || return 1
    { printf '\0' >&"$ProbeFd"; } 2>/dev/null || Status=1
    { exec {ProbeFd}>&-; } 2>/dev/null || Status=1
    return "$Status"
}

# Назначение: Скачивает один remote result через SCP во владение caller, проверяя captures и не перезаписывая существующий путь.
# shellcheck disable=SC2034  # Optional provenance is observed through a nameref.
fetch_remote_file()
{
    local DeviceId="$1"
    local RemoteName="$2"
    local LocalPath="$3"
    local FetchReasonSink=''
    local FetchReasonOutName="${4:-FetchReasonSink}"
    local ProvenanceRequested=false
    local DiagnosticPath=''
    local DiagnosticPathCleanup=''
    local DiagnosticFd=''
    local DiagnosticFdCleanup=''
    local OutputFd=''
    local OutputFdCleanup=''
    local PasswordFd=''
    local PasswordFdCleanup=''
    local ChildPid=''
    local RawStatus=0
    local ProjectCode=0
    local FinalCode=0
    local Status=0
    local SanitizedDiagnostic=''
    local DiagnosticReadStatus=0
    local DiagnosticRemoveStatus=0
    local ProbeStatus=0
    # The argv is populated through a nameref and consumed by name.
    # shellcheck disable=SC2034
    local -a TransportArgv=()

    [[ "$FetchReasonOutName" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 81
    local -n FetchReasonOut="$FetchReasonOutName"
    FetchReasonOut=''
    if (( $# >= 4 )); then
        ProvenanceRequested=true
    fi
    validate_remote_result_name "$RemoteName" || return $?
    validate_device_transport_context "$DeviceId" || return 80
    local -n FetchDeviceContext="$DeviceId"
    [[ -n "$LocalPath" ]] || return 80
    TransportDiagnostic=()
    create_private_transport_file diagnostic DiagnosticPath DiagnosticPathCleanup || return $?
    open_transport_output_fd /dev/null OutputFd OutputFdCleanup || Status=$?
    if (( Status == 0 )); then
        open_transport_output_fd "$DiagnosticPath" DiagnosticFd DiagnosticFdCleanup || Status=$?
    fi
    if (( Status == 0 )); then
        open_password_channel "${FetchDeviceContext[Password]}" PasswordFd PasswordFdCleanup || Status=$?
    fi
    if (( Status == 0 )); then
        build_scp_argv "$DeviceId" "$PasswordFd" "$RemoteName" "$LocalPath" TransportArgv || Status=$?
    fi
    if (( Status == 0 )); then
        launch_transport_child TransportArgv "$OutputFd" "$DiagnosticFd" ChildPid || Status=$?
    fi
    if (( Status != 0 )); then
        if [[ -n "$PasswordFd" ]]; then close_password_channel "$PasswordFd" "$PasswordFdCleanup" || :; fi
        if [[ -n "$DiagnosticFd" ]]; then close_registered_fd "$DiagnosticFd" "$DiagnosticFdCleanup" || :; fi
        if [[ -n "$OutputFd" ]]; then close_registered_fd "$OutputFd" "$OutputFdCleanup" || :; fi
        remove_private_transport_file "$DiagnosticPath" "$DiagnosticPathCleanup" || :
        (( Status == 80 || Status == 81 )) && return "$Status"
        return 40
    fi
    wait_transport_child "$ChildPid" RawStatus || Status=$?
    close_password_channel "$PasswordFd" "$PasswordFdCleanup" || Status=80
    close_registered_fd "$DiagnosticFd" "$DiagnosticFdCleanup" || Status=80
    close_registered_fd "$OutputFd" "$OutputFdCleanup" || Status=80
    (( Status == 0 )) || return "$Status"
    read_sanitized_bounded_diagnostic "$DiagnosticPath" \
        "${FetchDeviceContext[Password]}" "${FetchDeviceContext[User]}" \
        "${FetchDeviceContext[Address]}" SanitizedDiagnostic || DiagnosticReadStatus=$?
    if (( DiagnosticReadStatus == 0 )); then
        classify_scp_transport_result "$RawStatus" "$SanitizedDiagnostic" ProjectCode || return 80
    else
        ProjectCode=40
    fi
    remove_transport_capture_file "$DiagnosticPath" "$DiagnosticPathCleanup" || DiagnosticRemoveStatus=$?
    select_transport_capture_result scp "$ProjectCode" \
        "$DiagnosticReadStatus" 0 "$DiagnosticRemoveStatus" 0 FinalCode || return 80
    TransportDiagnostic[Operation]=scp_fetch
    TransportDiagnostic[RawStatus]="$RawStatus"
    TransportDiagnostic[ProjectCode]="$FinalCode"
    TransportDiagnostic[Text]="$SanitizedDiagnostic"
    if (( FinalCode == 43 )) && [[ "$ProvenanceRequested" == true ]]; then
        probe_fetch_destination_write "$LocalPath" || ProbeStatus=$?
        case "$ProbeStatus" in
            0) : ;;
            1) FetchReasonOut=local_destination_write ;;
            *) return 80 ;;
        esac
    fi
    return "$FinalCode"
}

# ==============================================================================
# RouterOS operation primitives
# ==============================================================================

# Назначение: Оборачивает RouterOS-команду без результата в уникальные action frame-маркеры драйвера.
build_routeros_action_command()
{
    local OperationCommand="$1"
    local -n RouterCommandOut="$2"

    [[ -n "$OperationCommand" ]] || return 81
    RouterCommandOut=":do { :put \"${MikrotikDriver[FrameActionBegin]}\"; $OperationCommand; :put \"${MikrotikDriver[FrameActionOk]}\" } on-error={ :put \"${MikrotikDriver[FrameActionError]}\" }"
    return 0
}

# Назначение: Оборачивает RouterOS-выражение, возвращающее одну строку, в data frame-маркеры драйвера.
build_routeros_data_command()
{
    local DataExpression="$1"
    local -n RouterCommandOut="$2"

    [[ -n "$DataExpression" ]] || return 81
    # Output is observed through the caller-provided nameref.
    # shellcheck disable=SC2034
    RouterCommandOut=":do { :local MbValue $DataExpression; :put \"${MikrotikDriver[FrameDataBegin]}\"; :put \$MbValue; :put \"${MikrotikDriver[FrameDataEnd]}\" } on-error={ :put \"${MikrotikDriver[FrameActionError]}\" }"
    return 0
}

# Назначение: Запрашивает `/system identity` и возвращает единственное проверенное имя устройства.
mikrotik_get_identity()
{
    local DeviceId="$1"
    local -n IdentityOut="$2"
    local RouterCommand=''
    local FramedOutput=''
    local IdentityValue=''
    local Status=0

    IdentityOut=''
    build_routeros_data_command '[/system identity get name]' RouterCommand || return 81
    execute_ssh_operation "$DeviceId" identity capture_text "$RouterCommand" '' FramedOutput || Status=$?
    (( Status == 0 )) || return "$Status"
    parse_routeros_data_frame "$FramedOutput" IdentityValue || return 42
    # Output is observed through the caller-provided nameref.
    # shellcheck disable=SC2034
    IdentityOut="$IdentityValue"
    return 0
}

# Назначение: Запускает RouterOS export с effective show-sensitive и форматом, затем подтверждает создание remote-файла.
mikrotik_create_text_export()
{
    local DeviceId="$1"
    local RemoteStem="$2"
    local ExportMode="${3:-compact}"
    local ShowSensitive="${4:-true}"
    local QuotedName=''
    local OperationCommand=''
    local RouterCommand=''
    local Parsed=''
    local Status=0

    validate_remote_creation_stem "$RemoteStem" || return $?
    validate_remote_result_name "${RemoteStem}.rsc" || return $?
    routeros_quote_string "$RemoteStem" QuotedName || return $?
    [[ "$ExportMode" == compact || "$ExportMode" == terse || "$ExportMode" == verbose ]] || return 80
    [[ "$ShowSensitive" == true || "$ShowSensitive" == false ]] || return 80
    OperationCommand="/export file=$QuotedName $ExportMode"
    if [[ "$ShowSensitive" == true ]]; then
        OperationCommand+=' show-sensitive'
    fi
    build_routeros_action_command "$OperationCommand" RouterCommand || return 81
    execute_ssh_operation "$DeviceId" text_export discard "$RouterCommand" || Status=$?
    (( Status == 0 )) || return "$Status"
    parse_routeros_action_frame \
        "${TransportDiagnostic[FramedOperationOutput]:-${TransportDiagnostic[OperationOutput]:-}}" \
        Parsed || return $?
    [[ "$Parsed" == success ]] || return 81
    return 0
}

# Назначение: Создаёт binary backup с effective encryption/password policy и подтверждает remote-результат.
mikrotik_create_binary_backup()
{
    local DeviceId="$1"
    local RemoteStem="$2"
    local QuotedName=''
    local OperationCommand=''
    local RouterCommand=''
    local Parsed=''
    local Occurrences=0
    local QuotedPassword=''
    local EncryptionPassword="${EffectiveConfig[encrypt]:-}"
    local EncryptionType="${EffectiveConfig[encrypt_type]:-aes-sha256}"
    local Status=0

    validate_mikrotik_driver_contract || return 81
    validate_remote_creation_stem "$RemoteStem" || return $?
    validate_remote_result_name "${RemoteStem}.backup" || return $?
    routeros_quote_string "$RemoteStem" QuotedName || return $?
    if [[ -z "$EncryptionPassword" ]]; then
        OperationCommand="/system backup save name=$QuotedName ${MikrotikDriver[BinaryStaticProperties]}"
        count_literal_occurrences "${OperationCommand,,}" 'dont-encrypt=yes' Occurrences || return 81
        (( Occurrences == 1 )) || return 81
        [[ "${OperationCommand,,}" != *'password='* && "${OperationCommand,,}" != *'encryption='* ]] || return 81
    else
        [[ "$EncryptionType" == aes-sha256 ]] || return 81
        routeros_quote_string "$EncryptionPassword" QuotedPassword || return $?
        OperationCommand="/system backup save name=$QuotedName password=$QuotedPassword encryption=$EncryptionType"
        [[ "${OperationCommand,,}" != *'dont-encrypt='* ]] || return 81
    fi
    build_routeros_action_command "$OperationCommand" RouterCommand || return 81
    execute_ssh_operation "$DeviceId" binary_backup discard "$RouterCommand" || Status=$?
    (( Status == 0 )) || return "$Status"
    parse_routeros_action_frame \
        "${TransportDiagnostic[FramedOperationOutput]:-${TransportDiagnostic[OperationOutput]:-}}" \
        Parsed || return $?
    [[ "$Parsed" == success ]] || return 81
    return 0
}

# Назначение: Читает числовой размер проверенного remote result через framed RouterOS-запрос.
# shellcheck disable=SC2034  # Optional reason output is observed through a nameref.
mikrotik_get_remote_size()
{
    local DeviceId="$1"
    local RemoteName="$2"
    local -n SizeOut="$3"
    local SizeReasonSink=''
    local SizeReasonOutName="${4:-SizeReasonSink}"
    local QuotedName=''
    local RouterCommand=''
    local FramedOutput=''
    local SizeValue=''
    local Status=0
    local AbsenceMarker='__MB2_REMOTE_FILE_ABSENT__'

    [[ "$SizeReasonOutName" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 81
    local -n SizeReasonOut="$SizeReasonOutName"

    SizeOut=''
    SizeReasonOut=''
    validate_remote_result_name "$RemoteName" || return $?
    routeros_quote_string "$RemoteName" QuotedName || return $?
    RouterCommand=":do { :local MbMatches [/file find where name=$QuotedName]; :if ([:len \$MbMatches] = 0) do={ :put \"${MikrotikDriver[FrameDataBegin]}\"; :put \"$AbsenceMarker\"; :put \"${MikrotikDriver[FrameDataEnd]}\" } else={ :if ([:len \$MbMatches] != 1) do={ :error \"selection\" }; :local MbValue [/file get [:pick \$MbMatches 0] size]; :put \"${MikrotikDriver[FrameDataBegin]}\"; :put \$MbValue; :put \"${MikrotikDriver[FrameDataEnd]}\" } } on-error={ :put \"${MikrotikDriver[FrameActionError]}\" }"
    execute_ssh_operation "$DeviceId" remote_size capture_text "$RouterCommand" '' FramedOutput || Status=$?
    (( Status == 0 )) || return "$Status"
    parse_routeros_data_frame "$FramedOutput" SizeValue || return 42
    if [[ "$SizeValue" == "$AbsenceMarker" ]]; then
        SizeReasonOut=absent
        return 42
    fi
    [[ "$SizeValue" =~ ^[0-9]+$ ]] || return 42
    # Output is observed through the caller-provided nameref.
    # shellcheck disable=SC2034
    SizeOut="$SizeValue"
    return 0
}

# Назначение: Удаляет ровно один проверенный remote result и подтверждает успешный action frame.
mikrotik_remove_remote_result()
{
    local DeviceId="$1"
    local RemoteName="$2"
    local QuotedName=''
    local OperationCommand=''
    local RouterCommand=''
    local Parsed=''
    local Status=0

    validate_remote_result_name "$RemoteName" || return $?
    routeros_quote_string "$RemoteName" QuotedName || return $?
    OperationCommand=":local MbMatches [/file find where name=$QuotedName]; :if ([:len \$MbMatches] > 1) do={ :error \"selection\" }; :if ([:len \$MbMatches] = 1) do={ /file remove [:pick \$MbMatches 0] }"
    build_routeros_action_command "$OperationCommand" RouterCommand || return 81
    execute_ssh_operation "$DeviceId" remote_remove discard "$RouterCommand" || Status=$?
    (( Status == 0 )) || return "$Status"
    parse_routeros_action_frame \
        "${TransportDiagnostic[FramedOperationOutput]:-${TransportDiagnostic[OperationOutput]:-}}" \
        Parsed || return $?
    [[ "$Parsed" == success ]] || return 81
    return 0
}

# Назначение: Выполняет запрошенную очистку DNS cache как отдельную pre-backup операцию RouterOS.
mikrotik_flush_dns_cache()
{
    local DeviceId="$1"
    local RouterCommand=''
    local Parsed=''
    local Status=0

    [[ "${MikrotikDriver[CapabilityDnsCleanup]:-false}" == true ]] || return 81
    build_routeros_action_command '/ip dns cache flush' RouterCommand || return 81
    execute_ssh_operation "$DeviceId" dns_cleanup discard "$RouterCommand" || Status=$?
    (( Status == 0 )) || return "$Status"
    parse_routeros_action_frame \
        "${TransportDiagnostic[FramedOperationOutput]:-${TransportDiagnostic[OperationOutput]:-}}" \
        Parsed || return $?
    [[ "$Parsed" == success ]] || return 81
    return 0
}

# Назначение: Очищает RouterOS console history по effective-политике до создания артефактов.
mikrotik_clear_console_history()
{
    local DeviceId="$1"
    local RouterCommand=''
    local Parsed=''
    local Status=0

    [[ "${MikrotikDriver[CapabilityConsoleHistoryCleanup]:-false}" == true ]] || return 81
    build_routeros_action_command 'console clear-history' RouterCommand || return 81
    execute_ssh_operation "$DeviceId" console_history_cleanup discard "$RouterCommand" || Status=$?
    (( Status == 0 )) || return "$Status"
    parse_routeros_action_frame \
        "${TransportDiagnostic[FramedOperationOutput]:-${TransportDiagnostic[OperationOutput]:-}}" \
        Parsed || return $?
    [[ "$Parsed" == success ]] || return 81
    return 0
}

# ==============================================================================
# Backup artifact pipeline and retry
# ==============================================================================

# Назначение: Добавляет этап к трассе backup pipeline, сохраняя порядок операций для проверок.
append_backup_trace()
{
    local Event="$1"

    RuntimeState[BackupTrace]+="${RuntimeState[BackupTrace]:+ }$Event"
    if [[ -n "${RuntimeState[BackupTracePath]:-}" ]]; then
        printf '%s\n' "$Event" >> "${RuntimeState[BackupTracePath]}" 2>/dev/null || :
    fi
    return 0
}

# Назначение: Выбирает более сильный из двух результатов по общей политике success/warning/error.
# shellcheck disable=SC2034  # ResultOut is a nameref output.
select_stronger_result()
{
    local Current="$1"
    local Candidate="$2"
    local -n ResultOut="$3"

    if (( Current == 0 || Current == 1 && Candidate != 0 && Candidate != 1 )); then
        ResultOut="$Candidate"
    else
        ResultOut="$Current"
    fi
    return 0
}

# Назначение: Распознаёт коды, после которых дальнейшие форматы или устройства обрабатывать небезопасно.
pipeline_stop_code()
{
    case "$1" in
        65|80|81) return 0 ;;
        *) return 1 ;;
    esac
}

# Назначение: Распознаёт результаты, означающие повреждённый/неподтверждённый локальный артефакт.
# shellcheck disable=SC2034  # CodeOut is a nameref output.
artifact_integrity_code()
{
    local Format="$1"
    local -n CodeOut="$2"

    case "$Format" in
        rsc) CodeOut=51 ;;
        backup) CodeOut=53 ;;
        *) return 80 ;;
    esac
    return 0
}

# Назначение: Фиксирует один календарный timestamp устройства, общий для имён всех форматов текущего backup.
# shellcheck disable=SC2034  # TimestampOut is a nameref output.
capture_backup_timestamp()
{
    local -n TimestampOut="$1"
    local Captured=''

    Captured="$(LC_ALL=C date '+%Y-%m-%d_%H-%M' 2>/dev/null)" || return 80
    [[ "$Captured" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}$ ]] || return 80
    TimestampOut="$Captured"
    return 0
}

# Назначение: Создаёт ограниченный уникальный stem для временных результатов на RouterOS.
# shellcheck disable=SC2034  # StemOut is a nameref output.
build_remote_backup_stem()
{
    local DeviceId="$1"
    local Timestamp="$2"
    local -n StemOut="$3"
    local DeviceOrdinal=''
    local TimestampDigits="${Timestamp//[^0-9]/}"

    StemOut=''
    [[ "$DeviceId" =~ ^DeviceContext_([1-9][0-9]*)$ ]] || return 80
    DeviceOrdinal="${BASH_REMATCH[1]}"
    [[ "$Timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}$ ]] || return 80
    StemOut="mb2_${BASHPID}_${DeviceOrdinal}_${TimestampDigits}"
    validate_remote_creation_stem "$StemOut" || return 80
    return 0
}

# Назначение: Строит каноническое имя локального артефакта из device, timestamp и расширения.
# shellcheck disable=SC2034  # PathOut is a nameref output.
build_local_artifact_path()
{
    local DeviceName="$1"
    local Timestamp="$2"
    local Format="$3"
    local DeviceDirectory="$4"
    local -n PathOut="$5"
    local FilenameIdentity="${DeviceName// /_}"

    PathOut=''
    validate_device_name "$DeviceName" >/dev/null 2>&1 || return 80
    [[ "$Timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}$ &&
       -n "$DeviceDirectory" && "$DeviceDirectory" != */ ]] || return 80
    case "$Format" in
        rsc|backup|log) : ;;
        *) return 80 ;;
    esac
    PathOut="$DeviceDirectory/${FilenameIdentity}_${Timestamp}.${Format}"
    return 0
}

# Назначение: Реализует test seam фиксированной паузы между допустимыми повторными попытками формата.
artifact_retry_delay()
{
    sleep 2 || return 80
    return 0
}

# Назначение: Удаляет только owned локальный артефакт через cleanup identity и сохраняет чужую замену.
remove_local_artifact_object()
{
    local Path="$1"
    local -a RemoveCommand=(rm -f -- "$Path")

    "${RemoveCommand[@]}" 2>/dev/null
}

# Назначение: Возвращает точный размер regular-файла без следования неподходящему объекту.
# shellcheck disable=SC2034  # SizeOut is a nameref output.
read_local_artifact_size()
{
    local Path="$1"
    local -n SizeOut="$2"
    local Observed=''

    Observed="$(LC_ALL=C stat -Lc '%s' -- "$Path" 2>/dev/null)" || return 1
    [[ "$Observed" =~ ^[0-9]+$ ]] || return 1
    SizeOut="$Observed"
    return 0
}

# Назначение: После локального отказа различает потерю общего storage и ошибку только текущего артефакта.
classify_active_artifact_storage_failure()
{
    local RecheckStatus=0

    case "${ExecutionState[RunMode]:-}" in
        single) return 37 ;;
        batch)
            recheck_common_storage || RecheckStatus=$?
            if (( RecheckStatus == 0 )); then
                StorageContext[StopBatch]=false
                return 64
            fi
            (( RecheckStatus == 80 )) && return 80
            StorageContext[StopBatch]=true
            return 65
            ;;
        *) return 80 ;;
    esac
}

# Назначение: Эксклюзивно создаёт локальную цель, регистрирует identity и передаёт владение backup pipeline.
# shellcheck disable=SC2034  # CleanupIdOut is a nameref output.
create_local_artifact_object()
{
    local Path="$1"
    local CleanupIdOutName="$2"
    local -n CleanupIdOut="$CleanupIdOutName"
    local CreatedDevice=''
    local CreatedInode=''
    local ObservedDevice=''
    local ObservedInode=''
    local Type=''
    local Owner=''
    local Mode=''
    local Created=false
    local IdentityCaptured=false
    local Status=0
    local -a ChmodCommand=(chmod 0600 -- "$Path")

    CleanupIdOut=''
    if attempt_noclobber_redirection "$Path"; then
        Created=true
    else
        return 1
    fi
    if cleanup_path_identity "$Path" CreatedDevice CreatedInode; then
        IdentityCaptured=true
    else
        Status=1
    fi
    if (( Status == 0 )); then
        "${ChmodCommand[@]}" 2>/dev/null || Status=1
    fi
    if (( Status == 0 )); then
        stat_path_metadata \
            "$Path" false Type Owner Mode ObservedDevice ObservedInode || Status=1
        [[ "$Type" == regular*file && "$Mode" == 600 &&
           "$ObservedDevice" == "$CreatedDevice" &&
           "$ObservedInode" == "$CreatedInode" ]] || Status=1
        # A qualified network filesystem may expose a server-mapped st_uid.
        if [[ "${StorageContext[NetworkMode]:-false}" != true && "$Owner" != "$UID" ]]; then
            Status=1
        fi
    fi
    if (( Status == 0 )); then
        register_cleanup_entry file "$Path" true \
            "$CreatedDevice" "$CreatedInode" "$CleanupIdOutName" || Status=$?
    fi
    if (( Status != 0 )); then
        if [[ "$Created" == true && "$IdentityCaptured" == true ]]; then
            remove_just_created_probe_object \
                file "$Path" "$CreatedDevice" "$CreatedInode" || :
        fi
        CleanupIdOut=''
        (( Status == 80 )) && return 80
        return 1
    fi
    return 0
}

# Назначение: Проверяет отсутствие целевого имени и подготавливает owned placeholder до SCP.
# shellcheck disable=SC2034  # CleanupIdOut is a nameref output.
prepare_local_artifact_destination()
{
    local DeviceDirectory="$1"
    local LocalPath="$2"
    local CleanupIdOutName="$3"
    local -n CleanupIdOut="$CleanupIdOutName"
    local Status=0

    CleanupIdOut=''
    [[ -d "$DeviceDirectory" && ! -L "$DeviceDirectory" &&
       "$LocalPath" == "$DeviceDirectory/"* && "${LocalPath#"$DeviceDirectory/"}" != */* ]] || return 80
    if [[ -e "$LocalPath" || -L "$LocalPath" ]]; then
        if [[ ! -f "$LocalPath" || -L "$LocalPath" ]]; then
            classify_active_artifact_storage_failure
            return $?
        fi
        remove_local_artifact_object "$LocalPath" || Status=$?
        if (( Status != 0 )); then
            (( Status == 80 )) && return 80
            classify_active_artifact_storage_failure
            return $?
        fi
        append_backup_trace local_replaced
    fi
    Status=0
    create_local_artifact_object "$LocalPath" "$CleanupIdOutName" || Status=$?
    if (( Status != 0 )); then
        (( Status == 80 )) && return 80
        classify_active_artifact_storage_failure
        return $?
    fi
    append_backup_trace local_created
    return 0
}

# Назначение: Удаляет неподтверждённый локальный файл, не затирая более ранний результат операции.
cleanup_local_artifact()
{
    local LocalPath="$1"
    local CleanupId="$2"
    local Declaration=''
    local Status=0

    [[ -n "$CleanupId" ]] || return 0
    Declaration="$(declare -p "$CleanupId" 2>/dev/null)" || return 80
    [[ "$Declaration" == "declare -A $CleanupId="* ]] || return 80
    local -n ArtifactCleanupEntry="$CleanupId"
    if [[ "${ArtifactCleanupEntry[Active]:-false}" == false ]]; then
        return 0
    fi
    [[ "${ArtifactCleanupEntry[Active]:-false}" == true &&
       "${ArtifactCleanupEntry[Type]:-}" == file &&
       "${ArtifactCleanupEntry[Value]:-}" == "$LocalPath" ]] || return 80
    if [[ ! -e "$LocalPath" && ! -L "$LocalPath" ]]; then
        unregister_cleanup_entry "$CleanupId" || return 80
        return 0
    fi
    cleanup_entry_matches_path "$CleanupId" || Status=$?
    if (( Status == 0 )); then
        remove_local_artifact_object "$LocalPath" || Status=$?
    fi
    if (( Status != 0 )); then
        (( Status == 80 )) && return 80
        classify_active_artifact_storage_failure
        return $?
    fi
    unregister_cleanup_entry "$CleanupId" || return 80
    append_backup_trace local_cleanup
    return 0
}

# Назначение: Сверяет локальный размер с remote size и оставляет только целостный owned артефакт.
validate_local_artifact()
{
    local LocalPath="$1"
    local CleanupId="$2"
    local RemoteSize="$3"
    local IntegrityCode="$4"
    local LocalSize=''
    local Status=0

    [[ "$RemoteSize" =~ ^[1-9][0-9]*$ && "$IntegrityCode" =~ ^(51|53)$ ]] || return 80
    if [[ ! -e "$LocalPath" && ! -L "$LocalPath" ]]; then
        unregister_cleanup_entry "$CleanupId" || return 80
        return "$IntegrityCode"
    fi
    if [[ ! -f "$LocalPath" || -L "$LocalPath" ]]; then
        classify_active_artifact_storage_failure
        return $?
    fi
    cleanup_entry_matches_path "$CleanupId" || Status=$?
    if (( Status != 0 )); then
        (( Status == 80 )) && return 80
        classify_active_artifact_storage_failure
        return $?
    fi
    read_local_artifact_size "$LocalPath" LocalSize || Status=$?
    if (( Status != 0 )); then
        (( Status == 80 )) && return 80
        classify_active_artifact_storage_failure
        return $?
    fi
    if (( LocalSize == 0 || LocalSize != RemoteSize )); then
        return "$IntegrityCode"
    fi
    unregister_cleanup_entry "$CleanupId" || return 80
    append_backup_trace local_valid
    return 0
}

# Назначение: Best-effort удаляет временный результат RouterOS, сохраняя основной код и stop-состояние.
cleanup_remote_artifact()
{
    local DeviceId="$1"
    local RemoteName="$2"
    local Status=0

    mikrotik_remove_remote_result "$DeviceId" "$RemoteName" || Status=$?
    if (( Status == 0 )); then
        append_backup_trace remote_cleanup
        return 0
    fi
    if (( Status == 80 || Status == 81 )); then
        return "$Status"
    fi
    record_warning remote_artifact_cleanup_failed
    append_backup_trace remote_cleanup_warning
    return 0
}

# Назначение: Выполняет полный create/size/fetch/validate/remote-cleanup цикл одного rsc или backup формата.
# shellcheck disable=SC2034  # ArtifactContext records the active attempt for diagnostics/tests.
run_backup_format_attempt()
{
    local DeviceId="$1"
    local Format="$2"
    local RemoteStem="$3"
    local RemoteName="$4"
    local LocalPath="$5"
    local AttemptNumber="$6"
    local IntegrityCode=0
    local FailureCode=0
    local StageStatus=0
    local CleanupStatus=0
    local RemoteSize=''
    local RemoteSizeReason=''
    local FetchFailureReason=''
    local LocalCleanupId=''
    local RemoteAttempted=false
    local StepStateKey="DeviceSubeventNumber:$DeviceId"
    local StepNumber=0
    local WarningCountBefore=0

    artifact_integrity_code "$Format" IntegrityCode || return 80
    [[ "$AttemptNumber" == 1 || "$AttemptNumber" == 2 ]] || return 80
    ArtifactContext=(
        [DeviceId]="$DeviceId" [Format]="$Format" [Attempt]="$AttemptNumber"
        [RemoteStem]="$RemoteStem" [RemoteName]="$RemoteName" [LocalPath]="$LocalPath"
    )
    append_backup_trace "$Format:attempt:$AttemptNumber:create"
    RemoteAttempted=true
    StepNumber="${LoggingState[$StepStateKey]:-0}"
    StepNumber=$((StepNumber + 1))
    LoggingState["$StepStateKey"]="$StepNumber"
    emit_runtime_log_event shell device subevent full "$DeviceId" \
        log_device_create_remote '' ordinary "$StepNumber" none \
        none '' '' '' '' device_main || :
    case "$Format" in
        rsc) mikrotik_create_text_export "$DeviceId" "$RemoteStem" \
                "${EffectiveConfig[export_format]:-compact}" \
                "${EffectiveConfig[show_sensitive]:-true}" || FailureCode=$? ;;
        backup) mikrotik_create_binary_backup "$DeviceId" "$RemoteStem" || FailureCode=$? ;;
        *) return 80 ;;
    esac
    if (( FailureCode != 0 )); then
        emit_runtime_log_event shell device subevent error "$DeviceId" \
            log_device_create_remote "$FailureCode" error "$StepNumber" none \
            none '' '' '' '' device_main || :
    fi

    if (( FailureCode == 0 )); then
        append_backup_trace "$Format:attempt:$AttemptNumber:size"
        StepNumber="${LoggingState[$StepStateKey]:-0}"
        StepNumber=$((StepNumber + 1))
        LoggingState["$StepStateKey"]="$StepNumber"
        emit_runtime_log_event shell device subevent full "$DeviceId" \
            log_device_read_remote_size '' ordinary "$StepNumber" none \
            none '' '' '' '' device_main || :
        mikrotik_get_remote_size "$DeviceId" "$RemoteName" RemoteSize RemoteSizeReason || StageStatus=$?
        if (( StageStatus != 0 )); then
            if (( StageStatus == 42 )) && [[ "$RemoteSizeReason" == absent ]]; then
                FailureCode="$IntegrityCode"
            else
                FailureCode="$StageStatus"
            fi
        elif [[ ! "$RemoteSize" =~ ^[0-9]+$ ]]; then
            FailureCode=80
        elif (( RemoteSize == 0 )); then
            FailureCode="$IntegrityCode"
        fi
        if (( FailureCode != 0 )); then
            emit_runtime_log_event shell device subevent error "$DeviceId" \
                log_device_read_remote_size "$FailureCode" error "$StepNumber" none \
                none '' '' '' '' device_main || :
        fi
    fi

    if (( FailureCode == 0 )); then
        append_backup_trace "$Format:attempt:$AttemptNumber:prepare-local"
        StepNumber="${LoggingState[$StepStateKey]:-0}"
        StepNumber=$((StepNumber + 1))
        LoggingState["$StepStateKey"]="$StepNumber"
        emit_runtime_log_event shell device subevent full "$DeviceId" \
            log_device_prepare_local '' ordinary "$StepNumber" none \
            none '' '' '' '' device_main || :
        prepare_local_artifact_destination "${LocalPath%/*}" "$LocalPath" LocalCleanupId || FailureCode=$?
        if (( FailureCode != 0 )); then
            emit_runtime_log_event shell device subevent error "$DeviceId" \
                log_device_prepare_local "$FailureCode" error "$StepNumber" none \
                none '' '' '' '' device_main || :
        fi
    fi
    if (( FailureCode == 0 )); then
        append_backup_trace "$Format:attempt:$AttemptNumber:fetch"
        StageStatus=0
        StepNumber="${LoggingState[$StepStateKey]:-0}"
        StepNumber=$((StepNumber + 1))
        LoggingState["$StepStateKey"]="$StepNumber"
        emit_runtime_log_event shell device subevent full "$DeviceId" \
            log_device_fetch_file '' ordinary "$StepNumber" none \
            none '' '' '' '' device_main || :
        fetch_remote_file \
            "$DeviceId" "$RemoteName" "$LocalPath" FetchFailureReason || StageStatus=$?
        if (( StageStatus != 0 )); then
            if (( StageStatus == 43 )) &&
               [[ "$FetchFailureReason" == local_destination_write ]]; then
                classify_active_artifact_storage_failure || FailureCode=$?
                (( FailureCode != 0 )) || FailureCode=80
            else
                FailureCode="$StageStatus"
            fi
        fi
        if (( FailureCode != 0 )); then
            emit_runtime_log_event shell device subevent error "$DeviceId" \
                log_device_fetch_file "$FailureCode" error "$StepNumber" none \
                none '' '' '' '' device_main || :
        fi
    fi
    if (( FailureCode == 0 )); then
        append_backup_trace "$Format:attempt:$AttemptNumber:validate"
        StepNumber="${LoggingState[$StepStateKey]:-0}"
        StepNumber=$((StepNumber + 1))
        LoggingState["$StepStateKey"]="$StepNumber"
        emit_runtime_log_event shell device subevent full "$DeviceId" \
            log_device_validate_local '' ordinary "$StepNumber" none \
            none '' '' '' '' device_main || :
        validate_local_artifact "$LocalPath" "$LocalCleanupId" "$RemoteSize" "$IntegrityCode" || FailureCode=$?
        if (( FailureCode == 0 )); then
            LocalCleanupId=''
        else
            emit_runtime_log_event shell device subevent error "$DeviceId" \
                log_device_validate_local "$FailureCode" error "$StepNumber" none \
                none '' '' '' '' device_main || :
        fi
    fi

    if (( FailureCode != 0 )) && [[ -n "$LocalCleanupId" ]]; then
        StepNumber="${LoggingState[$StepStateKey]:-0}"
        StepNumber=$((StepNumber + 1))
        LoggingState["$StepStateKey"]="$StepNumber"
        emit_runtime_log_event shell device subevent full "$DeviceId" \
            log_device_cleanup_local '' ordinary "$StepNumber" none \
            none '' '' '' '' device_main || :
        cleanup_local_artifact "$LocalPath" "$LocalCleanupId" || CleanupStatus=$?
        if (( CleanupStatus != 0 )); then
            emit_runtime_log_event shell device subevent error "$DeviceId" \
                log_device_cleanup_local "$CleanupStatus" error "$StepNumber" none \
                none '' '' '' '' device_main || :
            select_stronger_result "$FailureCode" "$CleanupStatus" FailureCode
        fi
    fi
    if [[ "$RemoteAttempted" == true ]]; then
        CleanupStatus=0
        WarningCountBefore="${RuntimeState[WarningCount]:-0}"
        StepNumber="${LoggingState[$StepStateKey]:-0}"
        StepNumber=$((StepNumber + 1))
        LoggingState["$StepStateKey"]="$StepNumber"
        emit_runtime_log_event shell device subevent full "$DeviceId" \
            log_device_cleanup_remote '' ordinary "$StepNumber" none \
            none '' '' '' '' device_main || :
        cleanup_remote_artifact "$DeviceId" "$RemoteName" || CleanupStatus=$?
        if (( CleanupStatus != 0 )); then
            emit_runtime_log_event shell device subevent error "$DeviceId" \
                log_device_cleanup_remote "$CleanupStatus" error "$StepNumber" none \
                none '' '' '' '' device_main || :
            select_stronger_result "$FailureCode" "$CleanupStatus" FailureCode
        elif (( ${RuntimeState[WarningCount]:-0} > WarningCountBefore )); then
            emit_runtime_log_event shell device subevent error "$DeviceId" \
                log_device_cleanup_remote 1 error "$StepNumber" none \
                none '' '' '' '' device_main || :
        fi
    fi
    ArtifactContext[Result]="$FailureCode"
    return "$FailureCode"
}

# Назначение: Повторяет разрешённые ошибки формата, объединяет результаты и останавливается на stop-кодах.
run_backup_format_pipeline()
{
    local DeviceId="$1"
    local Format="$2"
    local RemoteStem="$3"
    local RemoteName="$4"
    local LocalPath="$5"
    local Attempt=0
    local Status=0
    local StepStateKey="DeviceSubeventNumber:$DeviceId"
    local StepNumber=0

    for Attempt in 1 2; do
        Status=0
        run_backup_format_attempt \
            "$DeviceId" "$Format" "$RemoteStem" "$RemoteName" "$LocalPath" "$Attempt" || Status=$?
        RunState["${DeviceId}.${Format}.Attempts"]="$Attempt"
        if (( Status == 0 )); then
            RunState["${DeviceId}.${Format}.Result"]=0
            return 0
        fi
        if pipeline_stop_code "$Status"; then
            RunState["${DeviceId}.${Format}.Result"]="$Status"
            return "$Status"
        fi
        if (( Attempt == 1 )); then
            RunState["${DeviceId}.${Format}.FirstFailure"]="$Status"
            append_backup_trace "$Format:retry-delay"
            StepNumber="${LoggingState[$StepStateKey]:-0}"
            StepNumber=$((StepNumber + 1))
            LoggingState["$StepStateKey"]="$StepNumber"
            emit_runtime_log_event shell device subevent full "$DeviceId" \
                log_device_retry_delay '' ordinary "$StepNumber" none \
                none '' '' '' '' device_main || :
            if ! artifact_retry_delay; then
                emit_runtime_log_event shell device subevent error "$DeviceId" \
                    log_device_retry_delay 80 error "$StepNumber" none \
                    none '' '' '' '' device_main || :
                return 80
            fi
        fi
    done
    RunState["${DeviceId}.${Format}.Result"]="$Status"
    return "$Status"
}

# ==============================================================================
# Incremental comparison and duplicate pruning
# ==============================================================================

# Назначение: Добавляет этап к трассе incremental comparison для воспроизводимой проверки ветвлений.
append_incremental_trace()
{
    local Event="$1"

    RuntimeState[IncrementalTrace]+="${RuntimeState[IncrementalTrace]:+ }$Event"
    return 0
}

# Назначение: Проверяет timestamp имени backup по точному формату и реальному календарю.
# Private predicate: status 1 means only that the timestamp is noncanonical.
backup_timestamp_is_canonical()
{
    local Timestamp="$1"
    local Year=0 Month=0 Day=0 Hour=0 Minute=0 MaximumDay=0

    [[ "$Timestamp" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})_([0-9]{2})-([0-9]{2})$ ]] || return 1
    Year=$((10#${BASH_REMATCH[1]}))
    Month=$((10#${BASH_REMATCH[2]}))
    Day=$((10#${BASH_REMATCH[3]}))
    Hour=$((10#${BASH_REMATCH[4]}))
    Minute=$((10#${BASH_REMATCH[5]}))
    (( Year > 0 && Month >= 1 && Month <= 12 && Hour <= 23 && Minute <= 59 )) || return 1
    case "$Month" in
        1|3|5|7|8|10|12) MaximumDay=31 ;;
        4|6|9|11) MaximumDay=30 ;;
        2)
            MaximumDay=28
            if (( Year % 400 == 0 || (Year % 4 == 0 && Year % 100 != 0) )); then
                MaximumDay=29
            fi
            ;;
        *) return 1 ;;
    esac
    (( Day >= 1 && Day <= MaximumDay ))
}

# Назначение: Проверяет дату/время заголовка RouterOS export до нормализации сравнения.
rsc_header_timestamp_is_canonical()
{
    local Timestamp="$1"
    local FilenameTimestamp=''
    local Second=0

    [[ "$Timestamp" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})[[:space:]]([0-9]{2}):([0-9]{2}):([0-9]{2})$ ]] || return 1
    FilenameTimestamp="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
    Second=$((10#${BASH_REMATCH[4]}))
    backup_timestamp_is_canonical "$FilenameTimestamp" || return 1
    (( Second <= 59 ))
}

# Назначение: Выбирает ближайший прежний артефакт того же device/type, исключая текущий и неканонические имена.
# shellcheck disable=SC2034  # PreviousPathOut is a nameref output.
select_previous_artifact()
{
    local DeviceName="$1"
    local CurrentTimestamp="$2"
    local Format="$3"
    local DeviceDirectory="$4"
    local CurrentPath="$5"
    local -n PreviousPathOut="$6"
    local FilenameIdentity="${DeviceName// /_}"
    local ExpectedCurrentPath=''
    local Candidate=''
    local CandidateName=''
    local CandidateTimestamp=''
    local SelectedTimestamp=''
    local HadNullglob=false
    local -a Candidates=()
    local LC_ALL=C

    PreviousPathOut=''
    backup_timestamp_is_canonical "$CurrentTimestamp" || return 80
    case "$Format" in
        rsc|backup) : ;;
        *) return 80 ;;
    esac
    [[ -d "$DeviceDirectory" && ! -L "$DeviceDirectory" ]] || return 80
    build_local_artifact_path "$DeviceName" "$CurrentTimestamp" "$Format" \
        "$DeviceDirectory" ExpectedCurrentPath || return 80
    [[ "$ExpectedCurrentPath" == "$CurrentPath" ]] || return 80

    shopt -q nullglob && HadNullglob=true
    shopt -s nullglob
    Candidates=("$DeviceDirectory/${FilenameIdentity}_"*."$Format")
    [[ "$HadNullglob" == true ]] || shopt -u nullglob

    for Candidate in "${Candidates[@]}"; do
        [[ "$Candidate" != "$CurrentPath" ]] || continue
        CandidateName="${Candidate##*/}"
        CandidateTimestamp="${CandidateName#"${FilenameIdentity}_"}"
        CandidateTimestamp="${CandidateTimestamp%".$Format"}"
        backup_timestamp_is_canonical "$CandidateTimestamp" || continue
        [[ "$CandidateTimestamp" < "$CurrentTimestamp" ]] || continue
        if [[ -z "$SelectedTimestamp" || "$SelectedTimestamp" < "$CandidateTimestamp" ]]; then
            SelectedTimestamp="$CandidateTimestamp"
            PreviousPathOut="$Candidate"
        fi
    done
    return 0
}

# Назначение: Открывает артефакт только для чтения и сохраняет его identity для защиты от подмены во время digest.
# The state output is safe or unsafe; unsafe comparison input is warning-only.
# shellcheck disable=SC2034  # FdOut, FdPathOut and StateOut are nameref outputs.
open_comparison_artifact()
{
    local Path="$1"
    local -n FdOut="$2"
    local -n FdPathOut="$3"
    local -n StateOut="$4"
    local OpenedFd=0
    local OpenedFdPath=''
    local PathType='' PathOwner='' PathMode='' PathDevice='' PathInode=''
    local FdType='' FdOwner='' FdMode='' FdDevice='' FdInode=''

    FdOut=''
    FdPathOut=''
    StateOut=unsafe
    [[ -f "$Path" && ! -L "$Path" ]] || return 0
    { exec {OpenedFd}< "$Path"; } 2>/dev/null || return 0
    fd_path "$OpenedFd" OpenedFdPath || {
        exec {OpenedFd}<&-
        return 80
    }
    stat_path_metadata "$Path" false \
        PathType PathOwner PathMode PathDevice PathInode || {
        exec {OpenedFd}<&-
        return 0
    }
    stat_path_metadata "$OpenedFdPath" true \
        FdType FdOwner FdMode FdDevice FdInode || {
        exec {OpenedFd}<&-
        return 0
    }
    if [[ "$PathType" != regular*file || "$FdType" != regular*file ||
          "$PathDevice" != "$FdDevice" || "$PathInode" != "$FdInode" ]]; then
        exec {OpenedFd}<&-
        return 0
    fi
    FdOut="$OpenedFd"
    FdPathOut="$OpenedFdPath"
    StateOut=safe
    return 0
}

# Назначение: Повторно сверяет fd/path identity файла сравнения после чтения.
# shellcheck disable=SC2034  # MatchesOut is a nameref output.
comparison_artifact_identity_matches()
{
    local Path="$1"
    local FdPath="$2"
    local -n MatchesOut="$3"
    local PathType='' PathOwner='' PathMode='' PathDevice='' PathInode=''
    local FdType='' FdOwner='' FdMode='' FdDevice='' FdInode=''

    MatchesOut=false
    [[ -f "$Path" && ! -L "$Path" && -e "$FdPath" ]] || return 0
    stat_path_metadata "$Path" false \
        PathType PathOwner PathMode PathDevice PathInode || return 0
    stat_path_metadata "$FdPath" true \
        FdType FdOwner FdMode FdDevice FdInode || return 0
    if [[ "$PathType" == regular*file && "$FdType" == regular*file &&
          "$PathDevice" == "$FdDevice" && "$PathInode" == "$FdInode" ]]; then
        MatchesOut=true
    fi
    return 0
}

# Назначение: Вычисляет SHA-256 regular-артефакта и отвергает изменение identity во время чтения.
# shellcheck disable=SC2034  # DigestOut and StateOut are nameref outputs.
calculate_artifact_digest()
{
    local Path="$1"
    local -n DigestOut="$2"
    local -n StateOut="$3"
    local DigestRecord=''

    DigestOut=''
    StateOut=unproved
    DigestRecord="$(LC_ALL=C sha256sum -- "$Path" 2>/dev/null)" || return 0
    DigestRecord="${DigestRecord%% *}"
    [[ "$DigestRecord" =~ ^[0-9a-f]{64}$ ]] || return 0
    DigestOut="$DigestRecord"
    StateOut=ready
    return 0
}

# Назначение: Читает export до NUL либо EOF с различением полного чанка, конца и ошибки потока.
# RawStatusOut preserves the Bash read status for the byte-accounting owner.
# shellcheck disable=SC2034  # ChunkOut and RawStatusOut are nameref outputs.
read_rsc_nul_chunk()
{
    local Path="$1"
    local ReadFd="$2"
    local -n ChunkOut="$3"
    local -n RawStatusOut="$4"
    local LC_ALL=C

    : "$Path"
    ChunkOut=''
    RawStatusOut=0
    IFS= read -r -d '' -n 4096 ChunkOut <&"$ReadFd" || RawStatusOut=$?
    return 0
}

# Назначение: Проверяет допустимое расположение NUL в .rsc и запрещает скрытый хвост после terminator.
# shellcheck disable=SC2034  # NulStateOut is a nameref output.
inspect_rsc_nul_state()
{
    local Path="$1"
    local -n NulStateOut="$2"
    local ReadFd=0
    local ReadFdPath=''
    local Chunk=''
    local RawStatus=0
    local SizeBefore=''
    local SizeAfter=''
    local Consumed=0
    local LC_ALL=C

    NulStateOut=unproved
    read_local_artifact_size "$Path" SizeBefore || return 0
    { exec {ReadFd}< "$Path"; } 2>/dev/null || return 0
    fd_path "$ReadFd" ReadFdPath || {
        exec {ReadFd}<&-
        return 80
    }
    while :; do
        read_rsc_nul_chunk "$Path" "$ReadFd" Chunk RawStatus || {
            exec {ReadFd}<&-
            return 80
        }
        [[ "$RawStatus" =~ ^[0-9]+$ ]] || {
            exec {ReadFd}<&-
            return 80
        }
        Consumed=$((Consumed + ${#Chunk}))
        if (( RawStatus == 0 )) && (( ${#Chunk} < 4096 )); then
            NulStateOut=contains_nul
            exec {ReadFd}<&-
            return 0
        fi
        if (( RawStatus != 0 )); then
            read_local_artifact_size "$ReadFdPath" SizeAfter || {
                exec {ReadFd}<&-
                return 0
            }
            if [[ "$SizeBefore" == "$SizeAfter" ]] && (( Consumed == SizeBefore )); then
                NulStateOut=clean
            fi
            exec {ReadFd}<&-
            return 0
        fi
    done
}

# Назначение: Заменяет только канонический изменчивый timestamp заголовка export перед сравнением содержимого.
# shellcheck disable=SC2034  # NormalizedOut and StateOut are nameref outputs.
normalize_rsc_header()
{
    local HeaderBody="$1"
    local -n NormalizedOut="$2"
    local -n StateOut="$3"
    local HeaderPattern='^# [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} by RouterOS [^[:space:][:cntrl:]]+$'
    local LC_ALL=C

    NormalizedOut=''
    StateOut=not_narrow
    [[ "$HeaderBody" =~ $HeaderPattern ]] || return 0
    rsc_header_timestamp_is_canonical "${HeaderBody:2:19}" || return 0
    NormalizedOut="# 0000-00-00 00:00:00${HeaderBody:21}"
    StateOut=ready
    return 0
}

# Назначение: Вычисляет digest тела .rsc после проверенного смещения, сохраняя бинарную корректность чтения.
# sha256sum owns the body read and reports success only after complete EOF.
# shellcheck disable=SC2034  # DigestOut and StateOut are nameref outputs.
calculate_rsc_body_digest()
{
    local Path="$1"
    local ReadFd="$2"
    local -n DigestOut="$3"
    local -n StateOut="$4"
    local DigestRecord=''

    : "$Path"
    DigestOut=''
    StateOut=unproved
    DigestRecord="$(LC_ALL=C sha256sum <&"$ReadFd" 2>/dev/null)" || return 0
    DigestRecord="${DigestRecord%% *}"
    [[ "$DigestRecord" =~ ^[0-9a-f]{64}$ ]] || return 0
    DigestOut="$DigestRecord"
    StateOut=ready
    return 0
}

# Назначение: Строит digest .rsc без временного заголовка и подтверждает неизменность файла на всём проходе.
# shellcheck disable=SC2034  # DigestOut and StateOut are nameref outputs.
calculate_normalized_rsc_digest()
{
    local Path="$1"
    local -n DigestOut="$2"
    local -n StateOut="$3"
    local ReadFd=0
    local ReadFdPath=''
    local Header=''
    local HeaderBody=''
    local NormalizedHeader=''
    local HeaderState=''
    local Terminator=none
    local ReadStatus=0
    local HeaderBytes=0
    local SizeBefore=''
    local SizeAfter=''
    local BodyDigest=''
    local BodyState=''
    local DigestRecord=''
    local LC_ALL=C

    DigestOut=''
    StateOut=unproved
    read_local_artifact_size "$Path" SizeBefore || return 0
    { exec {ReadFd}< "$Path"; } 2>/dev/null || return 0
    fd_path "$ReadFd" ReadFdPath || {
        exec {ReadFd}<&-
        return 80
    }
    IFS= read -r Header <&"$ReadFd" || ReadStatus=$?
    HeaderBody="$Header"
    HeaderBytes=${#Header}
    if (( ReadStatus == 0 )); then
        HeaderBytes=$((HeaderBytes + 1))
        Terminator=lf
        if [[ "$HeaderBody" == *$'\r' ]]; then
            HeaderBody="${HeaderBody%$'\r'}"
            Terminator=crlf
        fi
    elif (( HeaderBytes != SizeBefore )); then
        exec {ReadFd}<&-
        return 0
    fi
    (( HeaderBytes <= SizeBefore )) || {
        exec {ReadFd}<&-
        return 0
    }
    normalize_rsc_header "$HeaderBody" NormalizedHeader HeaderState || {
        exec {ReadFd}<&-
        return 80
    }
    if [[ "$HeaderState" != ready ]]; then
        StateOut=not_narrow
        exec {ReadFd}<&-
        return 0
    fi
    calculate_rsc_body_digest "$Path" "$ReadFd" BodyDigest BodyState || {
        exec {ReadFd}<&-
        return 80
    }
    read_local_artifact_size "$ReadFdPath" SizeAfter || {
        exec {ReadFd}<&-
        return 0
    }
    exec {ReadFd}<&- || return 80
    [[ "$BodyState" == ready && "$SizeBefore" == "$SizeAfter" ]] || return 0
    DigestRecord="$(printf '%s:%s:%s:%s' \
        "${#NormalizedHeader}" "$NormalizedHeader" "$Terminator" "$BodyDigest" | \
        LC_ALL=C sha256sum)" || return 0
    DigestRecord="${DigestRecord%% *}"
    [[ "$DigestRecord" =~ ^[0-9a-f]{64}$ ]] || return 0
    DigestOut="$DigestRecord"
    StateOut=ready
    return 0
}

# Назначение: Сравнивает current/previous export по нормализованному digest, игнорируя только разрешённый timestamp.
# CompareStateOut is equal, different or unproved.
# shellcheck disable=SC2034  # CompareStateOut is a nameref output.
compare_rsc_artifacts()
{
    local PreviousPath="$1"
    local CurrentPath="$2"
    local -n CompareStateOut="$3"
    local PreviousDigest='' CurrentDigest=''
    local PreviousState='' CurrentState=''
    local PreviousNul='' CurrentNul=''

    CompareStateOut=unproved
    calculate_artifact_digest "$PreviousPath" PreviousDigest PreviousState || return 80
    calculate_artifact_digest "$CurrentPath" CurrentDigest CurrentState || return 80
    [[ "$PreviousState" == ready && "$CurrentState" == ready ]] || return 0
    if [[ "$PreviousDigest" == "$CurrentDigest" ]]; then
        CompareStateOut=equal
        return 0
    fi
    inspect_rsc_nul_state "$PreviousPath" PreviousNul || return 80
    inspect_rsc_nul_state "$CurrentPath" CurrentNul || return 80
    [[ "$PreviousNul" != unproved && "$CurrentNul" != unproved ]] || return 0
    if [[ "$PreviousNul" == contains_nul || "$CurrentNul" == contains_nul ]]; then
        CompareStateOut=different
        return 0
    fi
    calculate_normalized_rsc_digest "$PreviousPath" PreviousDigest PreviousState || return 80
    calculate_normalized_rsc_digest "$CurrentPath" CurrentDigest CurrentState || return 80
    if [[ "$PreviousState" == not_narrow || "$CurrentState" == not_narrow ]]; then
        CompareStateOut=different
    elif [[ "$PreviousState" != ready || "$CurrentState" != ready ]]; then
        CompareStateOut=unproved
    elif [[ "$PreviousDigest" == "$CurrentDigest" ]]; then
        CompareStateOut=equal
    else
        CompareStateOut=different
    fi
    return 0
}

# Назначение: Сравнивает binary backup побайтовым digest без содержательной нормализации.
# shellcheck disable=SC2034  # CompareStateOut is a nameref output.
compare_backup_artifacts()
{
    local PreviousPath="$1"
    local CurrentPath="$2"
    local -n CompareStateOut="$3"
    local PreviousSize=''
    local CurrentSize=''

    CompareStateOut=unproved
    read_local_artifact_size "$PreviousPath" PreviousSize || return 0
    read_local_artifact_size "$CurrentPath" CurrentSize || return 0
    if [[ "$PreviousSize" == "$CurrentSize" ]]; then
        CompareStateOut=equal
    else
        CompareStateOut=different
    fi
    return 0
}

# Назначение: Фиксирует нефатальную невозможность сравнения и оставляет новый артефакт сохранённым.
record_incremental_comparison_warning()
{
    local DeviceId="$1"
    local Format="$2"

    RunState["${DeviceId}.${Format}.IncrementalDecision"]=comparison_warning
    record_warning "incremental_comparison_unproved_${Format}"
    append_incremental_trace "$DeviceId:$Format:comparison_warning"
    return 0
}

# Назначение: Находит предыдущий артефакт, сравнивает его с новым и удаляет только доказанный дубликат current.
run_incremental_comparison()
{
    local DeviceId="$1"
    local DeviceName="$2"
    local Timestamp="$3"
    local Format="$4"
    local CurrentPath="$5"
    local PreviousPath=''
    local PreviousFd=''
    local PreviousFdPath=''
    local CurrentFd=''
    local CurrentFdPath=''
    local OpenState=''
    local CurrentOpenState=''
    local CompareState=''
    local IdentityMatches=false
    local CurrentIdentityMatches=false
    local Status=0

    [[ "$DeviceId" =~ ^DeviceContext_[1-9][0-9]*$ ]] || return 80
    case "$Format" in
        rsc|backup) : ;;
        *) return 80 ;;
    esac
    [[ -f "$CurrentPath" && ! -L "$CurrentPath" ]] || {
        classify_active_artifact_storage_failure
        return $?
    }
    select_previous_artifact "$DeviceName" "$Timestamp" "$Format" \
        "${CurrentPath%/*}" "$CurrentPath" PreviousPath || return $?
    RunState["${DeviceId}.${Format}.PreviousArtifact"]="${PreviousPath##*/}"
    if [[ -z "$PreviousPath" ]]; then
        RunState["${DeviceId}.${Format}.IncrementalDecision"]=no_previous
        append_incremental_trace "$DeviceId:$Format:no_previous"
        return 0
    fi

    open_comparison_artifact "$PreviousPath" PreviousFd PreviousFdPath OpenState || return $?
    if [[ "$OpenState" != safe ]]; then
        record_incremental_comparison_warning "$DeviceId" "$Format"
        return 0
    fi
    open_comparison_artifact \
        "$CurrentPath" CurrentFd CurrentFdPath CurrentOpenState || Status=$?
    if (( Status != 0 )) || [[ "$CurrentOpenState" != safe ]]; then
        { exec {PreviousFd}<&-; } 2>/dev/null || :
        (( Status == 80 )) && return 80
        classify_active_artifact_storage_failure
        return $?
    fi
    case "$Format" in
        rsc) compare_rsc_artifacts "$PreviousFdPath" "$CurrentFdPath" CompareState || Status=$? ;;
        backup) compare_backup_artifacts "$PreviousFdPath" "$CurrentFdPath" CompareState || Status=$? ;;
    esac
    comparison_artifact_identity_matches \
        "$PreviousPath" "$PreviousFdPath" IdentityMatches || Status=80
    comparison_artifact_identity_matches \
        "$CurrentPath" "$CurrentFdPath" CurrentIdentityMatches || Status=80
    { exec {PreviousFd}<&-; } 2>/dev/null || Status=80
    { exec {CurrentFd}<&-; } 2>/dev/null || Status=80
    (( Status == 0 )) || return "$Status"
    if [[ "$CurrentIdentityMatches" != true ]]; then
        classify_active_artifact_storage_failure
        return $?
    fi
    if [[ "$IdentityMatches" != true || "$CompareState" == unproved ]]; then
        record_incremental_comparison_warning "$DeviceId" "$Format"
        return 0
    fi
    if [[ "$CompareState" == different ]]; then
        RunState["${DeviceId}.${Format}.IncrementalDecision"]=changed
        append_incremental_trace "$DeviceId:$Format:changed"
        return 0
    fi
    [[ "$CompareState" == equal ]] || return 80

    remove_local_artifact_object "$CurrentPath" || Status=$?
    if (( Status != 0 )) || [[ -e "$CurrentPath" || -L "$CurrentPath" ]]; then
        RunState["${DeviceId}.${Format}.IncrementalDecision"]=prune_failed
        append_incremental_trace "$DeviceId:$Format:prune_failed"
        classify_active_artifact_storage_failure
        return $?
    fi
    RunState["${DeviceId}.${Format}.IncrementalDecision"]=unchanged
    append_incremental_trace "$DeviceId:$Format:unchanged"
    return 0
}

# ==============================================================================
# Monthly archive publication and source retirement
# ==============================================================================

# Назначение: Добавляет этап к архивной трассе, отражая фактический порядок build/publish/retirement.
append_archive_trace()
{
    local Event="$1"

    RuntimeState[ArchiveTrace]+="${RuntimeState[ArchiveTrace]:+ }$Event"
    return 0
}

# Назначение: Вычисляет предыдущий календарный день от переданной даты с переходами месяца, года и високосного февраля.
# shellcheck disable=SC2034  # PreviousOut is a nameref output.
previous_calendar_date()
{
    local DateValue="$1"
    local -n PreviousOut="$2"
    local Year=0
    local Month=0
    local Day=0
    local -a MonthDays=(0 31 28 31 30 31 30 31 31 30 31 30 31)

    PreviousOut=''
    [[ "$DateValue" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})$ ]] || return 80
    Year=$((10#${BASH_REMATCH[1]}))
    Month=$((10#${BASH_REMATCH[2]}))
    Day=$((10#${BASH_REMATCH[3]}))
    (( Year >= 1 && Month >= 1 && Month <= 12 )) || return 80
    if (( Year % 400 == 0 || Year % 4 == 0 && Year % 100 != 0 )); then
        MonthDays[2]=29
    fi
    (( Day >= 1 && Day <= MonthDays[Month] )) || return 80

    Day=$((Day - 1))
    if (( Day == 0 )); then
        Month=$((Month - 1))
        if (( Month == 0 )); then
            (( Year > 1 )) || return 80
            Year=$((Year - 1))
            Month=12
        fi
        if (( Year % 400 == 0 || Year % 4 == 0 && Year % 100 != 0 )); then
            MonthDays[2]=29
        else
            MonthDays[2]=28
        fi
        Day="${MonthDays[Month]}"
    fi
    printf -v PreviousOut '%02d.%02d.%04d' "$Day" "$Month" "$Year"
    return 0
}

# Назначение: Один раз фиксирует run date, due-day и имя ZIP за предыдущий день до длительного batch.
capture_monthly_archive_context()
{
    local ConfiguredDay="${EffectiveConfig[MonthlyArchive]:-false}"
    local CapturedDate=''
    local PreviousDate=''
    local ActualDay=0

    RuntimeState[MonthlyArchiveEnabled]=false
    RuntimeState[MonthlyArchiveDue]=false
    RuntimeState[MonthlyArchiveRunDate]=''
    RuntimeState[MonthlyArchiveDay]=''
    RuntimeState[MonthlyArchiveLabel]=''
    [[ "$ConfiguredDay" == false ]] && return 0
    [[ "$ConfiguredDay" =~ ^([1-9]|1[0-9]|2[0-8])$ ]] || return 80
    RuntimeState[MonthlyArchiveEnabled]=true
    RuntimeState[MonthlyArchiveDay]="$ConfiguredDay"

    CapturedDate="$(LC_ALL=C date '+%Y-%m-%d' 2>/dev/null)" || return 80
    previous_calendar_date "$CapturedDate" PreviousDate || return $?
    ActualDay=$((10#${CapturedDate##*-}))
    RuntimeState[MonthlyArchiveRunDate]="$CapturedDate"
    if (( ActualDay == 10#$ConfiguredDay )); then
        RuntimeState[MonthlyArchiveDue]=true
        RuntimeState[MonthlyArchiveLabel]="$PreviousDate"
    fi
    return 0
}

# Назначение: Отмечает служебное имя среди источников как предупреждение и исключает его из retirement.
record_archive_control_name_warning()
{
    local DeviceId="${1:-archive}"
    local WarningStateKey="${DeviceId}.ArchiveControlNameWarning"

    if [[ "${RunState[$WarningStateKey]:-false}" != true ]]; then
        RunState["$WarningStateKey"]=true
        record_warning archive_source_control_name_excluded
        append_archive_trace "$DeviceId:source_control_name_excluded"
    fi
    return 0
}

# Назначение: Собирает всё накопленное верхнего уровня каталога устройства, исключая защищённые служебные объекты и архивные каталоги.
# shellcheck disable=SC2034  # Array/path outputs are returned through namerefs.
collect_archive_source_candidates()
{
    local DeviceDirectory="$1"
    local DeviceId="$2"
    local -n CandidatesOut="$3"
    local -n DeviceJournalOut="$4"
    local -n MainJournalOut="$5"
    local Candidate=''
    local MainJournalPath=''
    local NullglobWasSet=false
    local DotglobWasSet=false
    local -a RawCandidates=()

    CandidatesOut=()
    DeviceJournalOut=''
    MainJournalOut=''
    [[ -d "$DeviceDirectory" && ! -L "$DeviceDirectory" ]] || return 80
    if [[ -n "$DeviceId" ]]; then
        resolve_device_journal_path "$DeviceId" DeviceJournalOut || return $?
        resolve_main_journal_path MainJournalPath || return $?
        MainJournalOut="$(realpath -m -- "$MainJournalPath" 2>/dev/null)" || return 1
    fi

    shopt -q nullglob && NullglobWasSet=true
    shopt -q dotglob && DotglobWasSet=true
    shopt -s nullglob dotglob
    if [[ -z "$DeviceId" ]]; then
        RawCandidates=("$DeviceDirectory"/*.rsc "$DeviceDirectory"/*.backup)
    else
        case "${ExecutionState[RunMode]:-}" in
            batch)
                if [[ "$DeviceJournalOut" != "$DeviceDirectory/"* ]]; then
                    [[ "$NullglobWasSet" == true ]] || shopt -u nullglob
                    [[ "$DotglobWasSet" == true ]] || shopt -u dotglob
                    return 80
                fi
                RawCandidates=("$DeviceDirectory"/*)
                ;;
            single)
                RawCandidates=("$DeviceDirectory"/*.rsc "$DeviceDirectory"/*.backup "$DeviceDirectory"/*.log)
                ;;
            *)
                [[ "$NullglobWasSet" == true ]] || shopt -u nullglob
                [[ "$DotglobWasSet" == true ]] || shopt -u dotglob
                return 80
                ;;
        esac
    fi
    [[ "$NullglobWasSet" == true ]] || shopt -u nullglob
    [[ "$DotglobWasSet" == true ]] || shopt -u dotglob

    for Candidate in "${RawCandidates[@]}"; do
        [[ -n "$DeviceJournalOut" && "$Candidate" == "$DeviceJournalOut" ]] && continue
        CandidatesOut+=("$Candidate")
    done
    [[ -z "$DeviceJournalOut" ]] || CandidatesOut+=("$DeviceJournalOut")
    return 0
}

# Назначение: Классифицирует candidate как допустимый regular source, исчезнувший объект или небезопасную замену.
# shellcheck disable=SC2034  # StateOut is a nameref output.
archive_source_candidate_state()
{
    local Candidate="$1"
    local ResolvedMainJournal="$2"
    local DeviceId="$3"
    local -n StateOut="$4"
    local Basename="${Candidate##*/}"
    local ResolvedCandidate=''
    local Type=''
    local Owner=''
    local Mode=''
    local Device=''
    local Inode=''
    local CleanupEntryId=''
    local CleanupDeclaration=''
    local ResolvedCleanupPath=''

    StateOut=excluded
    [[ -f "$Candidate" && ! -L "$Candidate" ]] || return 0
    if [[ "$Basename" == *[$'\001'-$'\037'$'\177']* ]]; then
        record_archive_control_name_warning "$DeviceId"
        return 0
    fi
    ResolvedCandidate="$(realpath -m -- "$Candidate" 2>/dev/null)" || return 1
    [[ -z "$ResolvedMainJournal" || "$ResolvedCandidate" != "$ResolvedMainJournal" ]] || return 0
    for CleanupEntryId in "${CleanupRegistry[@]}"; do
        CleanupDeclaration="$(declare -p "$CleanupEntryId" 2>/dev/null)" || continue
        [[ "$CleanupDeclaration" == "declare -A $CleanupEntryId="* ]] || continue
        local -n ArchiveActiveCleanup="$CleanupEntryId"
        if [[ "${ArchiveActiveCleanup[Active]:-false}" == true &&
              "${ArchiveActiveCleanup[Type]:-}" != fd &&
              -n "${ArchiveActiveCleanup[Value]:-}" ]]; then
            ResolvedCleanupPath="$(realpath -m -- "${ArchiveActiveCleanup[Value]}" 2>/dev/null)" || {
                unset -n ArchiveActiveCleanup
                return 1
            }
            if [[ "$ResolvedCandidate" == "$ResolvedCleanupPath" ]]; then
                unset -n ArchiveActiveCleanup
                return 0
            fi
        fi
        unset -n ArchiveActiveCleanup
    done
    if [[ "${ExecutionState[RunMode]:-}" == batch &&
          ( "$Basename" =~ ^(0[1-9]|1[0-2])-[0-9]{4}\.zip$ ||
            "$Basename" =~ ^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[0-2])\.[0-9]{4}\.zip$ ) ]]; then
        return 0
    fi
    stat_path_metadata "$Candidate" false Type Owner Mode Device Inode || return 1
    [[ "$Type" == regular*file ]] || return 0
    StateOut=eligible
    return 0
}

# Назначение: Проверяет, остался ли хотя бы один действительный source snapshot для построения архива.
# shellcheck disable=SC2034  # HasSourcesOut is a nameref output.
archive_sources_available()
{
    local DeviceDirectory="$1"
    local DeviceId="$2"
    local -n HasSourcesOut="$3"
    local Candidate=''
    local CandidateState=''
    local DeviceJournalPath=''
    local ResolvedMainJournal=''
    local -a Candidates=()

    HasSourcesOut=false
    collect_archive_source_candidates "$DeviceDirectory" "$DeviceId" \
        Candidates DeviceJournalPath ResolvedMainJournal || return $?
    for Candidate in "${Candidates[@]}"; do
        CandidateState=''
        archive_source_candidate_state \
            "$Candidate" "$ResolvedMainJournal" "$DeviceId" CandidateState || return $?
        [[ "$CandidateState" == eligible ]] && HasSourcesOut=true
    done
    return 0
}

# Назначение: Фиксирует имена, fd/identity и digests всех выбранных источников без фильтра по датам или расширениям.
# shellcheck disable=SC2034  # Array outputs are returned through namerefs.
discover_archive_sources()
{
    local DeviceDirectory="$1"
    local -n PathsOut="$2"
    local -n DevicesOut="$3"
    local -n InodesOut="$4"
    local -n DigestsOut="$5"
    local DeviceId="${6:-}"
    local Candidate=''
    local CandidateState=''
    local DeviceJournalPath=''
    local ResolvedMainJournal=''
    local Type=''
    local Owner=''
    local Mode=''
    local Device=''
    local Inode=''
    local Digest=''
    local -a Candidates=()

    PathsOut=()
    DevicesOut=()
    InodesOut=()
    DigestsOut=()
    (( $# < 7 )) || printf -v "$7" '%s' ''
    collect_archive_source_candidates "$DeviceDirectory" "$DeviceId" \
        Candidates DeviceJournalPath ResolvedMainJournal || return $?
    (( $# < 7 )) || printf -v "$7" '%s' "$DeviceJournalPath"
    for Candidate in "${Candidates[@]}"; do
        CandidateState=''
        archive_source_candidate_state \
            "$Candidate" "$ResolvedMainJournal" "$DeviceId" CandidateState || return $?
        [[ "$CandidateState" == eligible ]] || continue
        Type=''; Owner=''; Mode=''; Device=''; Inode=''; Digest=''
        stat_path_metadata "$Candidate" false Type Owner Mode Device Inode || return 1
        [[ "$Type" == regular*file ]] || continue
        read_archive_source_digest "$Candidate" Digest || return 1
        archive_regular_path_matches_identity "$Candidate" "$Device" "$Inode" || return 1
        PathsOut+=("$Candidate")
        DevicesOut+=("$Device")
        InodesOut+=("$Inode")
        DigestsOut+=("$Digest")
    done
    return 0
}

# Назначение: Выбирает строгую local metadata policy либо подтверждает server-mapped объект на квалифицированном network target.
# shellcheck disable=SC2034  # StrictOut is a nameref output.
resolve_archive_metadata_policy()
{
    local Path="$1"
    local Role="$2"
    local -n StrictOut="$3"
    local Canonical=''
    local Root="${StorageContext[CanonicalRoot]:-}"
    local -A ExpectedMount=()
    local -A ActualMount=()
    local -a RealpathCommand=(realpath -e -- "$Path")

    StrictOut=true
    case "$Role" in
        working) return 0 ;;
        directory|staging) ;;
        *) return 80 ;;
    esac
    [[ "${StorageContext[NetworkMode]:-false}" == true ]] || return 0
    [[ "${ExecutionState[RunMode]:-}" == batch &&
       "${StorageContext[Prepared]:-false}" == true &&
       "${LockContext[RootHeld]:-false}" == true &&
       "${LockContext[RootMode]:-}" == exclusive &&
       -n "$Root" && "$Root" != / && ! -L "$Path" ]] || return 1
    Canonical="$("${RealpathCommand[@]}" 2>/dev/null)" || return 1
    [[ "$Canonical" == "$Root/"* ]] || return 1
    ExpectedMount[ID]="${StorageContext[MountID]:-}"
    ExpectedMount[TARGET]="${StorageContext[MountTARGET]:-}"
    ExpectedMount[SOURCE]="${StorageContext[MountSOURCE]:-}"
    ExpectedMount[FSTYPE]="${StorageContext[MountFSTYPE]:-}"
    [[ -n "${ExpectedMount[ID]}" && -n "${ExpectedMount[TARGET]}" &&
       -n "${ExpectedMount[SOURCE]}" && -n "${ExpectedMount[FSTYPE]}" ]] || return 1
    inspect_mount "$Canonical" ActualMount || return 1
    same_mount_identity ExpectedMount ActualMount >/dev/null 2>&1 || return 1
    StrictOut=false
    return 0
}

# Назначение: Создаёт или проверяет канонический lowercase `archive/` внутри каталога устройства без миграции иных архивных каталогов.
prepare_archive_target_directory()
{
    local DeviceDirectory="$1"
    local -n DirectoryOut="$2"
    local ArchiveDirectory="$DeviceDirectory/archive"
    local Type=''
    local Owner=''
    local Mode=''
    local Device=''
    local Inode=''
    local StrictMetadata=true
    local PolicyStatus=0
    local -a MkdirCommand=()

    DirectoryOut=''
    [[ "${ExecutionState[RunMode]:-}" == batch &&
       "${StorageContext[Prepared]:-false}" == true &&
       "${LockContext[RootHeld]:-false}" == true &&
       "${LockContext[RootMode]:-}" == exclusive &&
       -d "$DeviceDirectory" && ! -L "$DeviceDirectory" ]] || return 80
    if [[ -e "$ArchiveDirectory" || -L "$ArchiveDirectory" ]]; then
        [[ -d "$ArchiveDirectory" && ! -L "$ArchiveDirectory" ]] || return 1
    else
        MkdirCommand=(mkdir -m 0700 -- "$ArchiveDirectory")
        "${MkdirCommand[@]}" 2>/dev/null || return 1
    fi
    stat_path_metadata "$ArchiveDirectory" false \
        Type Owner Mode Device Inode || return 1
    [[ "$Type" == directory ]] || return 1
    resolve_archive_metadata_policy \
        "$ArchiveDirectory" directory StrictMetadata || PolicyStatus=$?
    (( PolicyStatus == 0 )) || return "$PolicyStatus"
    if [[ "$StrictMetadata" == true ]]; then
        [[ "$Owner" == "$UID" && "$Mode" == 700 ]] || return 1
    fi
    # shellcheck disable=SC2034  # DirectoryOut is a nameref output.
    DirectoryOut="$ArchiveDirectory"
    return 0
}

# Назначение: Сверяет regular path с сохранёнными device/inode/owner/mode перед чтением либо удалением.
archive_regular_path_matches_identity()
{
    local Path="$1"
    local ExpectedDevice="$2"
    local ExpectedInode="$3"
    local Type=''
    local Owner=''
    local Mode=''
    local Device=''
    local Inode=''

    [[ -f "$Path" && ! -L "$Path" ]] || return 1
    stat_path_metadata "$Path" false Type Owner Mode Device Inode || return 1
    [[ "$Type" == regular*file && "$Device" == "$ExpectedDevice" &&
       "$Inode" == "$ExpectedInode" ]]
}

# Назначение: Вычисляет digest архивируемого source через уже открытый reference fd.
read_archive_source_digest()
{
    local Path="$1"
    local -n DigestOut="$2"
    local DigestRecord=''

    DigestOut=''
    DigestRecord="$(LC_ALL=C sha256sum 2>/dev/null < "$Path")" || return 1
    DigestOut="${DigestRecord%% *}"
    [[ "$DigestOut" =~ ^[0-9a-f]{64}$ ]]
}

# Назначение: Подтверждает неизменность source path, fd identity, size и digest относительно selection snapshot.
archive_source_matches_snapshot()
{
    local Path="$1"
    local ExpectedDevice="$2"
    local ExpectedInode="$3"
    local ExpectedDigest="$4"
    local ActualDigest=''

    [[ "$ExpectedDigest" =~ ^[0-9a-f]{64}$ ]] || return 80
    archive_regular_path_matches_identity \
        "$Path" "$ExpectedDevice" "$ExpectedInode" || return 1
    read_archive_source_digest "$Path" ActualDigest || return 1
    archive_regular_path_matches_identity \
        "$Path" "$ExpectedDevice" "$ExpectedInode" || return 1
    [[ "$ActualDigest" == "$ExpectedDigest" ]]
}

# Назначение: Повторно проверяет всю выборку перед публикацией и retirement, сохраняя первый отказ.
archive_sources_match_selection()
{
    local PathsName="$1"
    local DevicesName="$2"
    local InodesName="$3"
    local DigestsName="$4"
    local -n ArchiveSourcePaths="$PathsName"
    local -n ArchiveSourceDevices="$DevicesName"
    local -n ArchiveSourceInodes="$InodesName"
    local -n ArchiveSourceDigests="$DigestsName"
    local Index=0

    [[ ${#ArchiveSourcePaths[@]} -eq ${#ArchiveSourceDevices[@]} &&
       ${#ArchiveSourcePaths[@]} -eq ${#ArchiveSourceInodes[@]} &&
       ${#ArchiveSourcePaths[@]} -eq ${#ArchiveSourceDigests[@]} ]] || return 80
    for ((Index=0; Index<${#ArchiveSourcePaths[@]}; Index++)); do
        archive_source_matches_snapshot \
            "${ArchiveSourcePaths[Index]}" "${ArchiveSourceDevices[Index]}" \
            "${ArchiveSourceInodes[Index]}" "${ArchiveSourceDigests[Index]}" || return $?
    done
    return 0
}

# Назначение: Снимает состояние отсутствующего либо существующего ZIP и его identity для решения publish/repeat.
# shellcheck disable=SC2034  # Target outputs are returned through namerefs.
inspect_archive_target()
{
    local Path="$1"
    local -n StateOut="$2"
    local -n TargetDeviceOut="$3"
    local -n TargetInodeOut="$4"

    StateOut=''
    TargetDeviceOut=''
    TargetInodeOut=''
    if [[ ! -e "$Path" && ! -L "$Path" ]]; then
        StateOut=absent
        return 0
    fi
    if [[ ! -f "$Path" || -L "$Path" ]]; then
        StateOut=unsafe
        return 0
    fi
    cleanup_path_identity "$Path" TargetDeviceOut TargetInodeOut || return 1
    StateOut=regular
    return 0
}

# Назначение: Проверяет, что существующий target ZIP не был подменён после первоначальной инспекции.
archive_target_matches_snapshot()
{
    local Path="$1"
    local State="$2"
    local Device="$3"
    local Inode="$4"

    case "$State" in
        absent) [[ ! -e "$Path" && ! -L "$Path" ]] ;;
        regular) archive_regular_path_matches_identity "$Path" "$Device" "$Inode" ;;
        *) return 1 ;;
    esac
}

# Назначение: Возвращает fd заранее открытого target reference для точной проверки существующего ZIP.
# shellcheck disable=SC2034  # DescriptorOut is a nameref output.
archive_open_target_reference_fd()
{
    local Path="$1"
    local -n DescriptorOut="$2"

    { exec {DescriptorOut}< "$Path"; } 2>/dev/null
}

# Назначение: Открывает и регистрирует стабильную ссылку на существующий ZIP без передачи владения удалением.
# shellcheck disable=SC2034  # FD outputs are returned through namerefs.
open_archive_target_reference()
{
    local Path="$1"
    local ExpectedDevice="$2"
    local ExpectedInode="$3"
    local -n FdOut="$4"
    local -n FdPathOut="$5"
    local -n CleanupIdOut="$6"
    local ReferenceFd=0
    local ReferencePath=''
    local ReferenceType=''
    local ReferenceOwner=''
    local ReferenceMode=''
    local ReferenceDevice=''
    local ReferenceInode=''
    local CleanupEntryId=''
    local OpenStatus=0

    FdOut=''
    FdPathOut=''
    CleanupIdOut=''
    archive_open_target_reference_fd "$Path" ReferenceFd || OpenStatus=$?
    if (( OpenStatus != 0 )); then
        (( OpenStatus == 80 )) && return 80
        if archive_regular_path_matches_identity \
            "$Path" "$ExpectedDevice" "$ExpectedInode"; then
            return 2
        fi
        return 1
    fi
    register_cleanup_fd "$ReferenceFd" CleanupEntryId || {
        exec {ReferenceFd}<&-
        return 80
    }
    ReferencePath="/proc/${BASHPID}/fd/$ReferenceFd"
    stat_path_metadata "$ReferencePath" true \
        ReferenceType ReferenceOwner ReferenceMode ReferenceDevice ReferenceInode || {
        exec {ReferenceFd}<&-
        unregister_cleanup_entry "$CleanupEntryId" || :
        return 1
    }
    if [[ "$ReferenceType" != regular*file ||
          "$ReferenceDevice" != "$ExpectedDevice" ||
          "$ReferenceInode" != "$ExpectedInode" ]] ||
       ! archive_regular_path_matches_identity "$Path" "$ExpectedDevice" "$ExpectedInode"; then
        exec {ReferenceFd}<&-
        unregister_cleanup_entry "$CleanupEntryId" || :
        return 1
    fi
    FdOut="$ReferenceFd"
    FdPathOut="$ReferencePath"
    CleanupIdOut="$CleanupEntryId"
    return 0
}

# Назначение: Закрывает target reference и снимает соответствующую cleanup-регистрацию.
close_archive_target_reference()
{
    local ReferenceFd="$1"
    local CleanupEntryId="$2"

    [[ "$ReferenceFd" =~ ^[0-9]+$ && -n "$CleanupEntryId" ]] || return 80
    exec {ReferenceFd}<&- || return 80
    unregister_cleanup_entry "$CleanupEntryId" || return 80
    return 0
}

# Назначение: Создаёт новый архивный staging-файл с noclobber, не затрагивая существующую цель.
exclusive_create_archive_file()
{
    local Path="$1"

    attempt_noclobber_redirection "$Path"
}

# Назначение: Удаляет regular archive object только через предварительно проверенный path identity.
remove_archive_file_object()
{
    local Path="$1"
    local -a RemoveCommand=(rm -f -- "$Path")

    "${RemoveCommand[@]}" 2>/dev/null
}

# Назначение: Открывает принадлежащий archive-файл и сохраняет fd identity для последующих zip/unzip операций.
open_archive_reference_fd()
{
    local Path="$1"
    local EntryId="$2"
    local ReferenceFd=0
    local PathDevice=''
    local PathInode=''
    local ReferenceMetadata=''
    local -n ArchiveFdCleanupEntry="$EntryId"

    cleanup_path_identity "$Path" PathDevice PathInode || return 1
    { exec {ReferenceFd}<> "$Path"; } 2>/dev/null || return 1
    ReferenceMetadata="$(LC_ALL=C stat -Lc '%d:%i' -- "/proc/${BASHPID}/fd/$ReferenceFd" 2>/dev/null)" || {
        exec {ReferenceFd}>&-
        return 1
    }
    if [[ "$ReferenceMetadata" != "$PathDevice:$PathInode" ||
          "$PathDevice" != "${ArchiveFdCleanupEntry[Device]}" ||
          "$PathInode" != "${ArchiveFdCleanupEntry[Inode]}" ]]; then
        exec {ReferenceFd}>&-
        return 1
    fi
    ArchiveFdCleanupEntry[ReferenceFd]="$ReferenceFd"
    return 0
}

# Назначение: Закрывает archive reference и очищает связанное состояние владения.
close_archive_reference_fd()
{
    local EntryId="$1"
    local -n ArchiveReferenceCleanupEntry="$EntryId"
    local ReferenceFd="${ArchiveReferenceCleanupEntry[ReferenceFd]:-}"

    if [[ -n "$ReferenceFd" ]]; then
        [[ "$ReferenceFd" =~ ^[0-9]+$ ]] || return 80
        exec {ReferenceFd}>&- || return 80
        ArchiveReferenceCleanupEntry[ReferenceFd]=''
    fi
    return 0
}

# Назначение: После изменения ZIP обновляет сохранённые identity/size и подтверждает, что staging остаётся тем же объектом.
refresh_owned_archive_file()
{
    local Path="$1"
    local EntryId="$2"
    local -n ArchiveEntryToRefresh="$EntryId"
    local Type=''
    local Owner=''
    local Mode=''
    local Device=''
    local Inode=''
    local NewReferenceFd=0
    local ReferenceMetadata=''

    [[ "${ArchiveEntryToRefresh[Active]:-false}" == true &&
       "${ArchiveEntryToRefresh[Owned]:-false}" == true &&
       "${ArchiveEntryToRefresh[Type]:-}" == file &&
       "${ArchiveEntryToRefresh[Value]:-}" == "$Path" ]] || return 80
    [[ -f "$Path" && ! -L "$Path" ]] || return 1
    stat_path_metadata "$Path" false Type Owner Mode Device Inode || return 1
    [[ "$Type" == regular*file && "$Owner" == "$UID" && "$Mode" == 600 ]] || return 1
    { exec {NewReferenceFd}<> "$Path"; } 2>/dev/null || return 1
    ReferenceMetadata="$(LC_ALL=C stat -Lc '%d:%i' -- "/proc/${BASHPID}/fd/$NewReferenceFd" 2>/dev/null)" || {
        exec {NewReferenceFd}>&-
        return 1
    }
    if [[ "$ReferenceMetadata" != "$Device:$Inode" ]]; then
        exec {NewReferenceFd}>&-
        return 1
    fi
    close_archive_reference_fd "$EntryId" || {
        exec {NewReferenceFd}>&-
        return 80
    }
    ArchiveEntryToRefresh[Device]="$Device"
    ArchiveEntryToRefresh[Inode]="$Inode"
    ArchiveEntryToRefresh[ReferenceFd]="$NewReferenceFd"
    cleanup_entry_matches_path "$EntryId" || return 1
    return 0
}

# Назначение: Удаляет принадлежащий staging/work ZIP и корректно освобождает его reference/cleanup entry.
remove_owned_archive_file()
{
    local Path="$1"
    local EntryId="$2"
    local Declaration=''

    Declaration="$(declare -p "$EntryId" 2>/dev/null)" || return 80
    [[ "$Declaration" == "declare -A $EntryId="* ]] || return 80
    local -n ArchiveCleanupEntry="$EntryId"
    [[ "${ArchiveCleanupEntry[Active]:-false}" == true &&
       "${ArchiveCleanupEntry[Type]:-}" == file &&
       "${ArchiveCleanupEntry[Value]:-}" == "$Path" ]] || return 80
    cleanup_entry_matches_path "$EntryId" || return 1
    remove_archive_file_object "$Path" || return 1
    [[ ! -e "$Path" && ! -L "$Path" ]] || return 1
    close_archive_reference_fd "$EntryId" || return 80
    unregister_cleanup_entry "$EntryId" || return 80
    return 0
}

# Назначение: Удаляет archive path только при совпадении с явно переданным snapshot identity.
remove_archive_file_if_identity()
{
    local Path="$1"
    local Device="$2"
    local Inode="$3"

    archive_regular_path_matches_identity "$Path" "$Device" "$Inode" || return 1
    remove_archive_file_object "$Path" || return 1
    [[ ! -e "$Path" && ! -L "$Path" ]]
}

# Назначение: Создаёт приватный ZIP-файл, регистрирует cleanup и открывает устойчивую reference-ссылку на него.
# shellcheck disable=SC2034  # PathOut and EntryIdOut are nameref outputs.
create_owned_archive_file()
{
    local Directory="$1"
    local Role="$2"
    local -n PathOut="$3"
    local -n EntryIdOut="$4"
    local Attempt=0
    local Candidate=''
    local EntryId=''
    local Device=''
    local Inode=''
    local Type=''
    local Owner=''
    local Mode=''
    local VerifiedDevice=''
    local VerifiedInode=''
    local Status=0
    local DeferralStatus=0
    local CreateSucceeded=false
    local Owned=false
    local StrictMetadata=true
    local PolicyStatus=0

    PathOut=''
    EntryIdOut=''
    [[ -d "$Directory" && ! -L "$Directory" &&
       "$Role" =~ ^[a-z][a-z0-9-]*$ ]] || return 80
    for ((Attempt=0; Attempt<100; Attempt++)); do
        Candidate="$Directory/.mikrotik-archive-${Role}.${BASHPID}.${RANDOM}.${Attempt}.zip"
        EntryId=''; Device=''; Inode=''; Type=''; Owner=''; Mode=''
        VerifiedDevice=''; VerifiedInode=''; Status=0; DeferralStatus=0; PolicyStatus=0
        CreateSucceeded=false; Owned=false; StrictMetadata=true
        register_cleanup_entry file "$Candidate" false '' '' EntryId || return $?
        begin_signal_deferral || DeferralStatus=$?
        if (( DeferralStatus != 0 )); then
            unregister_cleanup_entry "$EntryId" || :
            return "$DeferralStatus"
        fi
        exclusive_create_archive_file "$Candidate" || Status=$?
        if (( Status == 0 )); then
            CreateSucceeded=true
            cleanup_path_identity "$Candidate" Device Inode || Status=$?
            if (( Status == 0 )); then
                mark_cleanup_entry_owned "$EntryId" "$Device" "$Inode" || Status=$?
                (( Status == 0 )) && Owned=true
            fi
            if (( Status == 0 )); then
                stat_path_metadata "$Candidate" false \
                    Type Owner Mode VerifiedDevice VerifiedInode || Status=$?
                if (( Status == 0 )); then
                    resolve_archive_metadata_policy \
                        "$Candidate" "$Role" StrictMetadata || PolicyStatus=$?
                    (( PolicyStatus == 0 )) || Status="$PolicyStatus"
                fi
                if [[ "$Type" != regular*file ||
                      ( "$StrictMetadata" == true &&
                        ( "$Owner" != "$UID" || "$Mode" != 600 ) ) ||
                      "$VerifiedDevice" != "$Device" ||
                      "$VerifiedInode" != "$Inode" ]]; then
                    Status=1
                fi
            fi
            if (( Status == 0 )); then
                open_archive_reference_fd "$Candidate" "$EntryId" || Status=$?
            fi
        fi
        if [[ "$CreateSucceeded" == true && $Status -ne 0 ]]; then
            if [[ "$Owned" == true ]]; then
                remove_owned_archive_file "$Candidate" "$EntryId" || :
            elif [[ -n "$Device" && -n "$Inode" ]]; then
                remove_archive_file_if_identity "$Candidate" "$Device" "$Inode" || :
                unregister_cleanup_entry "$EntryId" || :
            else
                unregister_cleanup_entry "$EntryId" || :
            fi
        elif [[ "$CreateSucceeded" != true ]]; then
            unregister_cleanup_entry "$EntryId" || Status=80
        fi
        end_signal_deferral || DeferralStatus=$?
        (( DeferralStatus == 0 )) || return "$DeferralStatus"
        if [[ "$CreateSucceeded" == true && $Status -eq 0 ]]; then
            PathOut="$Candidate"
            EntryIdOut="$EntryId"
            return 0
        fi
        if [[ "$CreateSucceeded" == true || $Status -eq 80 ]]; then
            (( Status == 80 )) && return 80
            return 1
        fi
        if [[ ! -e "$Candidate" && ! -L "$Candidate" ]]; then
            return 1
        fi
    done
    return 1
}

# Назначение: Инициализирует валидный пустой ZIP в owned working path для дальнейшего добавления members.
initialize_empty_working_archive()
{
    local Path="$1"

    printf 'PK\005\006\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000' > "$Path"
}

# Назначение: Копирует существующий target ZIP в working-файл без изменения оригинала до успешной публикации.
copy_archive_file()
{
    local Source="$1"
    local Destination="$2"
    local -a CopyCommand=(cp -- "$Source" "$Destination")

    "${CopyCommand[@]}" 2>/dev/null
}

# Назначение: Проверяет целостность ZIP по пути штатным unzip test до принятия либо публикации.
validate_zip_archive()
{
    local Path="$1"
    local -a ValidateCommand=(zip -T "$Path")

    LC_ALL=C "${ValidateCommand[@]}" >/dev/null 2>&1
}

# Назначение: Создаёт временный proc-fd alias для инструмента zip/unzip, не раскрывая подменяемый pathname.
# shellcheck disable=SC2034  # PathOut and EntryIdOut are nameref outputs.
create_archive_reference_alias()
{
    local ReferencePath="$1"
    local PrivateDirectory="$2"
    local ExpectedDevice="$3"
    local ExpectedInode="$4"
    local -n PathOut="$5"
    local -n EntryIdOut="$6"
    local Candidate="$PrivateDirectory/reference.zip"
    local EntryId=''
    local Device=''
    local Inode=''
    local ReferentMetadata=''
    local CreateStatus=0
    local DeferralStatus=0
    local RecoveryStatus=0
    local Created=false
    local Owned=false
    local -a LinkCommand=(ln -s -- "$ReferencePath" "$Candidate")

    PathOut=''
    EntryIdOut=''
    [[ -d "$PrivateDirectory" && ! -L "$PrivateDirectory" &&
       "$ReferencePath" =~ ^/proc/[0-9]+/fd/[0-9]+$ ]] || return 80
    register_cleanup_entry symlink "$Candidate" false '' '' EntryId || return $?
    begin_signal_deferral || DeferralStatus=$?
    if (( DeferralStatus != 0 )); then
        unregister_cleanup_entry "$EntryId" || :
        return "$DeferralStatus"
    fi
    "${LinkCommand[@]}" 2>/dev/null || CreateStatus=$?
    if (( CreateStatus == 0 )); then
        Created=true
        cleanup_path_identity "$Candidate" Device Inode || CreateStatus=$?
        if (( CreateStatus == 0 )); then
            mark_cleanup_entry_owned "$EntryId" "$Device" "$Inode" || CreateStatus=$?
            (( CreateStatus == 0 )) && Owned=true
        fi
        ReferentMetadata="$(LC_ALL=C stat -Lc '%d:%i' -- "$Candidate" 2>/dev/null)" || CreateStatus=$?
        if [[ "$ReferentMetadata" != "$ExpectedDevice:$ExpectedInode" ]]; then
            CreateStatus=1
        fi
    fi
    if [[ "$Created" == true && $CreateStatus -ne 0 ]]; then
        if [[ "$Owned" == true ]]; then
            remove_owned_probe_entry "$EntryId" || RecoveryStatus=$?
        else
            if [[ -n "$Device" && -n "$Inode" ]] &&
               archive_path_matches_identity "$Candidate" "$Device" "$Inode" &&
               [[ -L "$Candidate" ]]; then
                rm -f -- "$Candidate" 2>/dev/null || RecoveryStatus=$?
            fi
            unregister_cleanup_entry "$EntryId" || RecoveryStatus=80
        fi
    elif [[ "$Created" != true ]]; then
        unregister_cleanup_entry "$EntryId" || RecoveryStatus=80
    fi
    end_signal_deferral || DeferralStatus=$?
    (( DeferralStatus == 0 )) || return "$DeferralStatus"
    if [[ "$Created" == true && $CreateStatus -eq 0 ]]; then
        PathOut="$Candidate"
        EntryIdOut="$EntryId"
        return 0
    fi
    (( CreateStatus == 80 || RecoveryStatus == 80 )) && return 80
    return 1
}

# Назначение: Проверяет ZIP через стабильный reference fd и удаляет только созданный alias.
validate_zip_archive_reference()
{
    local ReferencePath="$1"
    local ExpectedDevice="$2"
    local ExpectedInode="$3"
    local Attempt=0
    local PrivateDirectory=''
    local DirectoryEntry=''
    local ReferenceAlias=''
    local AliasEntry=''
    local Created=false
    local Collision=false
    local ReferentMetadata=''
    local Status=0
    local CleanupStatus=0
    local -a ValidateCommand=()

    [[ "$ReferencePath" =~ ^/proc/[0-9]+/fd/[0-9]+$ &&
       "$ExpectedDevice" =~ ^[0-9]+$ && "$ExpectedInode" =~ ^[0-9]+$ ]] || return 80
    for ((Attempt=0; Attempt<100; Attempt++)); do
        PrivateDirectory="/tmp/.mikrotik-archive-reference.${BASHPID}.${RANDOM}.${Attempt}"
        DirectoryEntry=''
        Created=false
        Collision=false
        Status=0
        create_owned_probe_object directory "$PrivateDirectory" \
            DirectoryEntry Created Collision || Status=$?
        (( Status == 80 )) && return 80
        (( Status == 0 )) || return 1
        [[ "$Created" == true ]] && break
        [[ "$Collision" == true ]] || return 1
    done
    [[ "$Created" == true ]] || return 1

    create_archive_reference_alias \
        "$ReferencePath" "$PrivateDirectory" "$ExpectedDevice" "$ExpectedInode" \
        ReferenceAlias AliasEntry || Status=$?
    if (( Status == 0 )); then
        ReferentMetadata="$(LC_ALL=C stat -Lc '%d:%i' -- "$ReferenceAlias" 2>/dev/null)" || Status=$?
    fi
    if (( Status == 0 )) && [[ "$ReferentMetadata" != "$ExpectedDevice:$ExpectedInode" ]]; then
        Status=1
    fi
    if (( Status == 0 )); then
        ValidateCommand=(zip -T "$ReferenceAlias")
        LC_ALL=C "${ValidateCommand[@]}" >/dev/null 2>&1 || Status=$?
    fi
    if (( Status == 0 )); then
        ReferentMetadata="$(LC_ALL=C stat -Lc '%d:%i' -- "$ReferenceAlias" 2>/dev/null)" || Status=$?
    fi
    if (( Status == 0 )) && [[ "$ReferentMetadata" != "$ExpectedDevice:$ExpectedInode" ]]; then
        Status=1
    fi
    CleanupStatus=0
    cleanup_private_probe "$AliasEntry" "$DirectoryEntry" || CleanupStatus=$?
    (( Status == 80 || CleanupStatus == 80 )) && return 80
    (( Status == 0 && CleanupStatus == 0 )) || return 1
    return 0
}

# Назначение: Добавляет подготовленный source в working ZIP с точным member name и без рекурсивного захвата каталога.
update_working_archive()
{
    local WorkingPath="$1"
    local SourcesName="$2"
    local -n ArchiveSources="$SourcesName"
    local -a ZipCommand=(zip -q -j -MM -nw "$WorkingPath" --)

    (( ${#ArchiveSources[@]} > 0 )) || return 80
    ZipCommand+=("${ArchiveSources[@]}")
    LC_ALL=C "${ZipCommand[@]}" >/dev/null 2>&1
}

# Назначение: Экранирует glob-метасимволы имени member для буквального запроса к unzip.
# shellcheck disable=SC2034  # PatternOut is a nameref output.
escape_unzip_member_pattern()
{
    local MemberName="$1"
    local -n PatternOut="$2"
    local Character=''
    local Index=0
    local LC_ALL=C

    PatternOut=''
    [[ -n "$MemberName" && "$MemberName" != */* &&
       "$MemberName" != *[$'\001'-$'\037'$'\177']* ]] || return 80
    for ((Index=0; Index<${#MemberName}; Index++)); do
        Character="${MemberName:Index:1}"
        if (( Index == 0 )) && [[ "$Character" == - ]]; then
            PatternOut+='[-]'
            continue
        fi
        case "$Character" in
            '*') PatternOut+='[*]' ;;
            '?') PatternOut+='[?]' ;;
            '[') PatternOut+='[[]' ;;
            \\) PatternOut+="\\\\" ;;
            *) PatternOut+="$Character" ;;
        esac
    done
    return 0
}

# Назначение: Считает точные совпадения member name в ZIP и обнаруживает отсутствующие либо дублированные записи.
# shellcheck disable=SC2034  # CountOut is a nameref output.
count_exact_archive_member()
{
    local ArchivePath="$1"
    local MemberName="$2"
    local -n CountOut="$3"
    local Member=''
    local MemberList=''
    local MemberPattern=''
    local Status=0

    CountOut=0
    [[ -f "$ArchivePath" && ! -L "$ArchivePath" &&
       -n "$MemberName" && "$MemberName" != */* ]] || return 80
    escape_unzip_member_pattern "$MemberName" MemberPattern || return $?
    MemberList="$(LC_ALL=C unzip -Z1 "$ArchivePath" "$MemberPattern" 2>/dev/null)" || Status=$?
    if (( Status == 11 )); then
        [[ -z "$MemberList" ]] || return 1
        return 0
    fi
    (( Status == 0 )) || return 1
    while IFS= read -r Member; do
        [[ "$Member" == "$MemberName" ]] || return 1
        CountOut=$((CountOut + 1))
    done <<< "$MemberList"
    (( CountOut > 0 )) || return 1
    return 0
}

# Назначение: Объединяет прежний archived log member с полным текущим device-log, сохраняя обе истории.
# shellcheck disable=SC2034  # OverlapOut is a nameref output.
merge_archive_log_history()
{
    local PriorPath="$1"
    local CurrentPath="$2"
    local MergedPath="$3"
    local -n OverlapOut="$4"
    local PriorSize=0
    local CurrentSize=0
    local MaximumOverlap=0
    local ExpectedSize=0
    local MergedSize=0
    local PriorData=''
    local CurrentData=''
    local LC_ALL=C

    OverlapOut=0
    [[ -z "$PriorPath" || -f "$PriorPath" && ! -L "$PriorPath" ]] || return 1
    [[ -f "$CurrentPath" && ! -L "$CurrentPath" &&
       -f "$MergedPath" && ! -L "$MergedPath" ]] || return 80
    if [[ -n "$PriorPath" ]]; then
        PriorSize="$(LC_ALL=C stat -Lc '%s' -- "$PriorPath" 2>/dev/null)" || return 1
        [[ "$PriorSize" =~ ^[0-9]+$ ]] || return 1
        if (( PriorSize > 0 )); then
            IFS= read -r -N "$PriorSize" PriorData < "$PriorPath" || return 1
            (( ${#PriorData} == PriorSize )) || return 1
        fi
    fi
    CurrentSize="$(LC_ALL=C stat -Lc '%s' -- "$CurrentPath" 2>/dev/null)" || return 1
    [[ "$CurrentSize" =~ ^[0-9]+$ ]] || return 1
    if (( CurrentSize > 0 )); then
        IFS= read -r -N "$CurrentSize" CurrentData < "$CurrentPath" || return 1
        (( ${#CurrentData} == CurrentSize )) || return 1
    fi

    MaximumOverlap="$PriorSize"
    (( CurrentSize < MaximumOverlap )) && MaximumOverlap="$CurrentSize"
    for ((OverlapOut=MaximumOverlap; OverlapOut>0; OverlapOut--)); do
        [[ "${PriorData:PriorSize-OverlapOut}" == "${CurrentData:0:OverlapOut}" ]] && break
    done
    printf '%s%s' "$PriorData" "${CurrentData:OverlapOut}" > "$MergedPath" || return 1
    MergedSize="$(LC_ALL=C stat -Lc '%s' -- "$MergedPath" 2>/dev/null)" || return 1
    ExpectedSize=$((PriorSize + CurrentSize - OverlapOut))
    [[ "$MergedSize" == "$ExpectedSize" ]]
}

# Назначение: Удаляет только принадлежащие временные файлы сборки объединённого журнала и сохраняет первый код ошибки.
cleanup_archive_log_workspace()
{
    local ContextName="$1"
    local -n WorkspaceRun="$ContextName"
    local FileEntry="${WorkspaceRun[LogWorkspaceFileEntry]:-}"
    local DirectoryEntry="${WorkspaceRun[LogWorkspaceDirectoryEntry]:-}"

    [[ -n "$FileEntry" || -n "$DirectoryEntry" ]] || return 0
    cleanup_private_probe "$FileEntry" "$DirectoryEntry" || return $?
    WorkspaceRun[LogWorkspaceFileEntry]=''
    WorkspaceRun[LogWorkspaceDirectoryEntry]=''
    # shellcheck disable=SC2154  # Associative keys are reached through a nameref.
    WorkspaceRun[LogWorkspaceDirectory]=''
    # shellcheck disable=SC2154  # Associative keys are reached through a nameref.
    WorkspaceRun[LogMergedPath]=''
    return 0
}

# Назначение: Готовит единый log source для ZIP: полный старый журнал плюс сохранённая история существующего архива.
prepare_batch_archive_log_input()
{
    local ContextName="$1"
    local PathsName="$2"
    local UpdatePathsName="$3"
    local -n LogInputRun="$ContextName"
    local -n OriginalPaths="$PathsName"
    local -n UpdatePaths="$UpdatePathsName"
    local DeviceId="${LogInputRun[DeviceId]}"
    local DeviceJournalPath="${LogInputRun[DeviceJournalPath]}"
    local WorkingPath="${LogInputRun[WorkingPath]}"
    local TargetState="${LogInputRun[TargetState]}"
    local DeviceName=''
    local WorkspaceDirectory=''
    local WorkspaceFile=''
    local DirectoryEntry=''
    local FileEntry=''
    local PriorPath=''
    local MemberPattern=''
    local MemberCount=0
    local Overlap=0
    local Index=0
    local JournalIndex=-1
    local Attempt=0
    local Status=0
    local Created=false
    local Collision=false
    local -a ExtractCommand=()

    UpdatePaths=("${OriginalPaths[@]}")
    [[ "${ExecutionState[RunMode]:-}" == batch ]] || return 0
    [[ -n "$DeviceJournalPath" ]] || return 80
    for ((Index=0; Index<${#OriginalPaths[@]}; Index++)); do
        [[ "${OriginalPaths[Index]}" == "$DeviceJournalPath" ]] && JournalIndex="$Index"
    done
    (( JournalIndex >= 0 )) || return 0
    (( JournalIndex == ${#OriginalPaths[@]} - 1 )) || return 80
    local -n LogInputDevice="$DeviceId"
    DeviceName="${LogInputDevice[DeviceName]:-}"
    validate_device_name "$DeviceName" >/dev/null 2>&1 || return 80

    for ((Attempt=0; Attempt<100; Attempt++)); do
        WorkspaceDirectory="/tmp/.mikrotik-archive-log.${BASHPID}.${RANDOM}.${Attempt}"
        DirectoryEntry=''; Created=false; Collision=false
        create_owned_probe_object directory "$WorkspaceDirectory" \
            DirectoryEntry Created Collision || Status=$?
        (( Status == 0 )) || return "$Status"
        [[ "$Created" == true ]] && break
        [[ "$Collision" == true ]] || return 35
    done
    [[ "$Created" == true ]] || return 35
    WorkspaceFile="$WorkspaceDirectory/$DeviceName.log"
    FileEntry=''; Created=false; Collision=false; Status=0
    create_owned_probe_object file "$WorkspaceFile" \
        FileEntry Created Collision || Status=$?
    LogInputRun[LogWorkspaceDirectory]="$WorkspaceDirectory"
    LogInputRun[LogWorkspaceDirectoryEntry]="$DirectoryEntry"
    LogInputRun[LogWorkspaceFileEntry]="$FileEntry"
    LogInputRun[LogMergedPath]="$WorkspaceFile"
    if (( Status != 0 )) || [[ "$Created" != true || "$Collision" == true ]]; then
        (( Status != 0 )) || Status=35
        return "$Status"
    fi

    if [[ "$TargetState" == regular ]]; then
        count_exact_archive_member "$WorkingPath" "$DeviceName.log" MemberCount || return $?
        (( MemberCount <= 1 )) || return 1
        if (( MemberCount == 1 )); then
            escape_unzip_member_pattern "$DeviceName.log" MemberPattern || return $?
            ExtractCommand=(unzip -p "$WorkingPath" "$MemberPattern")
            LC_ALL=C "${ExtractCommand[@]}" > "$WorkspaceFile" 2>/dev/null || return 1
            cleanup_entry_matches_path "$FileEntry" || return 1
            PriorPath="$WorkspaceFile"
        fi
    fi
    merge_archive_log_history \
        "$PriorPath" "$DeviceJournalPath" "$WorkspaceFile" Overlap || return $?
    cleanup_entry_matches_path "$FileEntry" || return 1
    # shellcheck disable=SC2154  # Associative keys are reached through a nameref.
    LogInputRun[LogMemberCount]="$MemberCount"
    # shellcheck disable=SC2154  # Associative keys are reached through a nameref.
    LogInputRun[LogOverlap]="$Overlap"
    # shellcheck disable=SC2034  # UpdatePaths is a nameref output.
    UpdatePaths[JournalIndex]="$WorkspaceFile"
    return 0
}

# Назначение: Атомарно заменяет существующий точный target проверенным staging ZIP через mv -fT.
publish_archive_staging()
{
    local StagingPath="$1"
    local TargetPath="$2"
    local -a MoveCommand=(mv -fT -- "$StagingPath" "$TargetPath")

    "${MoveCommand[@]}" 2>/dev/null
}

# Назначение: Публикует staging как новый target, не разрешая перезапись внезапно появившегося ZIP.
publish_archive_staging_if_absent()
{
    local StagingPath="$1"
    local TargetPath="$2"
    local -a LinkCommand=(ln -T -- "$StagingPath" "$TargetPath")

    "${LinkCommand[@]}" 2>/dev/null
}

# Назначение: Переносит cleanup ownership с прежнего staging path на опубликованный target identity.
rebind_owned_archive_file()
{
    local EntryId="$1"
    local OldPath="$2"
    local NewPath="$3"
    local -n ArchiveEntryToRebind="$EntryId"

    [[ "${ArchiveEntryToRebind[Active]:-false}" == true &&
       "${ArchiveEntryToRebind[Owned]:-false}" == true &&
       "${ArchiveEntryToRebind[Type]:-}" == file &&
       "${ArchiveEntryToRebind[Value]:-}" == "$OldPath" ]] || return 80
    ArchiveEntryToRebind[Value]="$NewPath"
    if ! cleanup_entry_matches_path "$EntryId"; then
        ArchiveEntryToRebind[Value]="$OldPath"
        return 1
    fi
    return 0
}

# Назначение: Сверяет архивный path с сохранённым owned snapshot перед любым разрушительным действием.
archive_path_matches_identity()
{
    local Path="$1"
    local ExpectedDevice="$2"
    local ExpectedInode="$3"
    local ActualDevice=''
    local ActualInode=''

    cleanup_path_identity "$Path" ActualDevice ActualInode || return 1
    [[ "$ActualDevice" == "$ExpectedDevice" && "$ActualInode" == "$ExpectedInode" ]]
}

# Назначение: Подтверждает, что открытый reference fd всё ещё указывает на ожидаемый archive object.
archive_reference_matches_identity()
{
    local ReferencePath="$1"
    local ExpectedDevice="$2"
    local ExpectedInode="$3"
    local Type=''
    local Owner=''
    local Mode=''
    local Device=''
    local Inode=''

    stat_path_metadata "$ReferencePath" true Type Owner Mode Device Inode || return 1
    [[ "$Type" == regular*file && "$Device" == "$ExpectedDevice" &&
       "$Inode" == "$ExpectedInode" ]]
}

# Назначение: Сохраняет текущую identity ZIP в cleanup registry после доказанного создания/публикации.
register_owned_archive_identity()
{
    local Path="$1"
    local Device="$2"
    local Inode="$3"
    local EntryIdOutName="$4"

    archive_regular_path_matches_identity "$Path" "$Device" "$Inode" || return 1
    register_cleanup_entry file "$Path" true "$Device" "$Inode" "$EntryIdOutName"
}

# Назначение: Удаляет один source только если path и открытый snapshot всё ещё совпадают с выборкой.
remove_retired_archive_source()
{
    local SourcePath="$1"
    local QuarantinePath="$2"
    local EntryId="$3"

    : "$SourcePath"
    remove_owned_archive_file "$QuarantinePath" "$EntryId"
}

# Назначение: Предоставляет пустую test seam между selection и построением working ZIP.
archive_before_build_hook()
{
    :
}

# Назначение: Предоставляет test seam перед повторной проверкой существующего target.
archive_before_target_recheck_hook()
{
    :
}

# Назначение: Предоставляет test seam непосредственно перед атомарной публикацией ZIP.
archive_before_publish_hook()
{
    :
}

# Назначение: Предоставляет test seam перед общей фазой удаления опубликованных источников.
archive_before_source_cleanup_hook()
{
    :
}

# Назначение: Предоставляет test seam перед retirement конкретного source для моделирования гонок.
archive_before_source_retirement_hook()
{
    :
}

# Назначение: Сохраняет первый archive outcome, очищает только owned временные объекты и закрывает references.
finish_archive_failure()
{
    local DeviceId="$1"
    local Decision="$2"
    local InitialCode="$3"
    local WorkingPath="$4"
    local WorkingEntry="$5"
    local StagingPath="$6"
    local StagingEntry="$7"
    local TargetReferenceFd="${8:-}"
    local TargetReferenceCleanup="${9:-}"
    local Result="$InitialCode"
    local CleanupStatus=0
    local StorageCode=0

    if [[ -n "$StagingEntry" ]]; then
        remove_owned_archive_file "$StagingPath" "$StagingEntry" || CleanupStatus=$?
        if (( CleanupStatus != 0 )); then
            if (( CleanupStatus == 80 )); then
                StorageCode=80
            else
                classify_active_artifact_storage_failure || StorageCode=$?
                (( StorageCode != 0 )) || StorageCode=80
            fi
            select_stronger_result "$Result" "$StorageCode" Result
        fi
    fi
    CleanupStatus=0
    StorageCode=0
    if [[ -n "$WorkingEntry" ]]; then
        remove_owned_archive_file "$WorkingPath" "$WorkingEntry" || CleanupStatus=$?
        if (( CleanupStatus != 0 )); then
            if (( CleanupStatus == 80 )); then
                StorageCode=80
            else
                classify_active_artifact_storage_failure || StorageCode=$?
                (( StorageCode != 0 )) || StorageCode=80
            fi
            select_stronger_result "$Result" "$StorageCode" Result
        fi
    fi
    if [[ -n "$TargetReferenceFd" || -n "$TargetReferenceCleanup" ]]; then
        if ! close_archive_target_reference \
            "$TargetReferenceFd" "$TargetReferenceCleanup"; then
            select_stronger_result "$Result" 80 Result
        fi
    fi
    RunState["${DeviceId}.ArchiveDecision"]="$Decision"
    RunState["${DeviceId}.ArchiveCode"]="$InitialCode"
    append_archive_trace "$DeviceId:$Decision:$InitialCode:result:$Result"
    return "$Result"
}

# Назначение: После проверенной публикации удаляет неизменившиеся sources по одному и фиксирует частичный retirement.
remove_selected_archive_sources()
{
    local DeviceId="$1"
    local PathsName="$2"
    local DevicesName="$3"
    local InodesName="$4"
    local DigestsName="$5"
    local ProtectedLastPath="${6:-}"
    local -n ArchiveRemovalPaths="$PathsName"
    local -n ArchiveRemovalDevices="$DevicesName"
    local -n ArchiveRemovalInodes="$InodesName"
    local -n ArchiveRemovalDigests="$DigestsName"
    local Index=0
    local Result=0
    local Status=0
    local StorageCode=0
    local SourcePath=''
    local DeferralStatus=0
    local -a RemoveCommand=()

    [[ ${#ArchiveRemovalPaths[@]} -eq ${#ArchiveRemovalDevices[@]} &&
       ${#ArchiveRemovalPaths[@]} -eq ${#ArchiveRemovalInodes[@]} &&
       ${#ArchiveRemovalPaths[@]} -eq ${#ArchiveRemovalDigests[@]} ]] || return 80
    for ((Index=0; Index<${#ArchiveRemovalPaths[@]}; Index++)); do
        SourcePath="${ArchiveRemovalPaths[Index]}"
        Status=0
        StorageCode=0
        DeferralStatus=0

        if [[ -n "$ProtectedLastPath" && "$SourcePath" == "$ProtectedLastPath" &&
              $Result -ne 0 ]]; then
            append_archive_trace "$DeviceId:source_retained_after_failure:${SourcePath##*/}"
            break
        fi

        archive_before_source_retirement_hook "$DeviceId" "$SourcePath" '' "$Index"
        archive_source_matches_snapshot \
            "$SourcePath" "${ArchiveRemovalDevices[Index]}" \
            "${ArchiveRemovalInodes[Index]}" \
            "${ArchiveRemovalDigests[Index]}" || Status=$?
        if (( Status == 0 )); then
            begin_signal_deferral || DeferralStatus=$?
            if (( DeferralStatus == 0 )); then
                # Recheck immediately before unlink so in-place content changes
                # cannot retire bytes that were not included in the archive.
                archive_source_matches_snapshot \
                    "$SourcePath" "${ArchiveRemovalDevices[Index]}" \
                    "${ArchiveRemovalInodes[Index]}" \
                    "${ArchiveRemovalDigests[Index]}" || Status=$?
            else
                Status="$DeferralStatus"
            fi
            if (( Status == 0 )); then
                RemoveCommand=(rm -f -- "$SourcePath")
                "${RemoveCommand[@]}" 2>/dev/null || Status=1
            fi
            end_signal_deferral || DeferralStatus=$?
            (( DeferralStatus == 0 )) || Status="$DeferralStatus"
        fi
        if (( Status == 0 )); then
            append_archive_trace "$DeviceId:source_removed:${SourcePath##*/}"
            continue
        fi
        (( Status == 80 )) && StorageCode=80
        if (( StorageCode == 0 )); then
            classify_active_artifact_storage_failure || StorageCode=$?
            (( StorageCode != 0 )) || StorageCode=80
        fi
        select_stronger_result "$Result" "$StorageCode" Result
        append_archive_trace "$DeviceId:source_remove_failed:${SourcePath##*/}:$StorageCode"
        if pipeline_stop_code "$StorageCode"; then
            break
        fi
    done
    return "$Result"
}

# Назначение: Определяет target/repeat policy, открывает существующий ZIP и готовит owned working/staging объекты.
prepare_monthly_archive_target_phase()
{
    local ContextName="$1"
    local -n TargetPhaseRun="$ContextName"
    local DeviceId="${TargetPhaseRun[DeviceId]}"
    local DeviceDirectory="${TargetPhaseRun[DeviceDirectory]}"
    local -n TargetDirectory="${ContextName}[TargetDirectory]"
    local -n TargetPath="${ContextName}[TargetPath]"
    local -n TargetState="${ContextName}[TargetState]"
    local -n TargetDevice="${ContextName}[TargetDevice]"
    local -n TargetInode="${ContextName}[TargetInode]"
    local -n TargetReferenceFd="${ContextName}[TargetReferenceFd]"
    local -n TargetReferencePath="${ContextName}[TargetReferencePath]"
    local -n TargetReferenceCleanup="${ContextName}[TargetReferenceCleanup]"
    local Status=0
    local StorageCode=0

    if [[ "${ExecutionState[RunMode]:-}" == batch ]]; then
        prepare_archive_target_directory "$DeviceDirectory" TargetDirectory || Status=$?
        if (( Status != 0 )); then
            if (( Status == 80 )); then
                # shellcheck disable=SC2154  # Associative key is reached through a nameref.
                TargetPhaseRun[FailureDisposition]=direct
                TargetPhaseRun[FailureCode]=80
            else
                classify_active_artifact_storage_failure || StorageCode=$?
                (( StorageCode != 0 )) || StorageCode=80
                TargetPhaseRun[FailureDisposition]=finish
                # shellcheck disable=SC2154  # Associative key is reached through a nameref.
                TargetPhaseRun[FailureDecision]=storage_failure
                TargetPhaseRun[FailureCode]="$StorageCode"
            fi
            return 1
        fi
        TargetPath="$TargetDirectory/${TargetPhaseRun[ArchiveLabel]}.zip"
    fi
    inspect_archive_target "$TargetPath" TargetState TargetDevice TargetInode || Status=$?
    if (( Status != 0 )); then
        classify_active_artifact_storage_failure || StorageCode=$?
        (( StorageCode != 0 )) || StorageCode=80
        # shellcheck disable=SC2154  # Associative key is reached through a nameref.
        TargetPhaseRun[FailureDisposition]=finish
        # shellcheck disable=SC2154  # Associative key is reached through a nameref.
        TargetPhaseRun[FailureDecision]=storage_failure
        TargetPhaseRun[FailureCode]="$StorageCode"
        return 1
    fi
    if [[ "$TargetState" == unsafe ]]; then
        TargetPhaseRun[FailureDisposition]=finish
        TargetPhaseRun[FailureDecision]=validation_error
        TargetPhaseRun[FailureCode]=71
        return 1
    fi
    if [[ "$TargetState" == regular ]]; then
        open_archive_target_reference \
            "$TargetPath" "$TargetDevice" "$TargetInode" \
            TargetReferenceFd TargetReferencePath TargetReferenceCleanup || Status=$?
        if (( Status != 0 )); then
            if (( Status == 80 )); then
                TargetPhaseRun[FailureDisposition]=direct
                TargetPhaseRun[FailureCode]=80
            elif (( Status == 2 )); then
                classify_active_artifact_storage_failure || StorageCode=$?
                (( StorageCode != 0 )) || StorageCode=80
                TargetPhaseRun[FailureDisposition]=finish
                TargetPhaseRun[FailureDecision]=storage_failure
                TargetPhaseRun[FailureCode]="$StorageCode"
            else
                TargetPhaseRun[FailureDisposition]=finish
                TargetPhaseRun[FailureDecision]=validation_error
                TargetPhaseRun[FailureCode]=71
            fi
            return 1
        fi
        validate_zip_archive_reference \
            "$TargetReferencePath" "$TargetDevice" "$TargetInode" || Status=$?
        if (( Status != 0 )); then
            TargetPhaseRun[FailureDisposition]=finish
            if (( Status == 80 )); then
                TargetPhaseRun[FailureDecision]=internal_error
                TargetPhaseRun[FailureCode]=80
            else
                TargetPhaseRun[FailureDecision]=validation_error
                TargetPhaseRun[FailureCode]=71
            fi
            return 1
        fi
        if ! archive_target_matches_snapshot \
            "$TargetPath" "$TargetState" "$TargetDevice" "$TargetInode"; then
            TargetPhaseRun[FailureDisposition]=finish
            TargetPhaseRun[FailureDecision]=validation_error
            TargetPhaseRun[FailureCode]=71
            return 1
        fi
        append_archive_trace "$DeviceId:existing_valid"
    fi
    return 0
}

# Назначение: Строит ZIP из полного snapshot, объединяет старый log и проверяет members/целостность до публикации.
build_monthly_archive_working_phase()
{
    local ContextName="$1"
    local PathsName="$2"
    local DevicesName="$3"
    local InodesName="$4"
    local DigestsName="$5"
    # shellcheck disable=SC2178  # The nameref target is the caller's associative context.
    local -n WorkingPhaseRun="$ContextName"
    local DeviceId="${WorkingPhaseRun[DeviceId]}"
    local DeviceDirectory="${WorkingPhaseRun[DeviceDirectory]}"
    local TargetState="${WorkingPhaseRun[TargetState]}"
    local TargetReferencePath="${WorkingPhaseRun[TargetReferencePath]}"
    local -n WorkingPath="${ContextName}[WorkingPath]"
    local -n WorkingEntry="${ContextName}[WorkingEntry]"
    local -n ArchiveOriginalPaths="$PathsName"
    local Status=0
    local RefreshStatus=0
    local WorkspaceStatus=0
    local StorageCode=0
    local MemberCount=0
    local MemberName=''
    local Index=0
    local -a WorkingUpdatePaths=()

    create_owned_archive_file /tmp working WorkingPath WorkingEntry || Status=$?
    if (( Status != 0 )); then
        WorkingPhaseRun[FailureDisposition]=finish
        if (( Status == 80 )); then
            WorkingPhaseRun[FailureDecision]=internal_error
            WorkingPhaseRun[FailureCode]=80
        else
            classify_active_artifact_storage_failure || StorageCode=$?
            (( StorageCode != 0 )) || StorageCode=80
            WorkingPhaseRun[FailureDecision]=storage_failure
            WorkingPhaseRun[FailureCode]="$StorageCode"
        fi
        return 1
    fi
    if [[ "$TargetState" == regular ]]; then
        copy_archive_file "$TargetReferencePath" "$WorkingPath" || Status=$?
        if (( Status != 0 )) || ! cleanup_entry_matches_path "$WorkingEntry"; then
            classify_active_artifact_storage_failure || StorageCode=$?
            (( StorageCode != 0 )) || StorageCode=80
            WorkingPhaseRun[FailureDisposition]=finish
            WorkingPhaseRun[FailureDecision]=storage_failure
            WorkingPhaseRun[FailureCode]="$StorageCode"
            return 1
        fi
        if ! validate_zip_archive "$WorkingPath"; then
            WorkingPhaseRun[FailureDisposition]=finish
            WorkingPhaseRun[FailureDecision]=validation_error
            WorkingPhaseRun[FailureCode]=71
            return 1
        fi
    else
        initialize_empty_working_archive "$WorkingPath" || Status=$?
        if (( Status != 0 )) || ! cleanup_entry_matches_path "$WorkingEntry"; then
            classify_active_artifact_storage_failure || StorageCode=$?
            (( StorageCode != 0 )) || StorageCode=80
            WorkingPhaseRun[FailureDisposition]=finish
            WorkingPhaseRun[FailureDecision]=storage_failure
            WorkingPhaseRun[FailureCode]="$StorageCode"
            return 1
        fi
    fi

    if [[ "$TargetState" == regular ]]; then
        for ((Index=0; Index<${#ArchiveOriginalPaths[@]}; Index++)); do
            MemberName="${ArchiveOriginalPaths[Index]##*/}"
            MemberCount=0
            Status=0
            count_exact_archive_member \
                "$WorkingPath" "$MemberName" MemberCount || Status=$?
            if (( Status != 0 || MemberCount > 1 )); then
                WorkingPhaseRun[FailureDisposition]=finish
                if (( Status == 80 )); then
                    WorkingPhaseRun[FailureDecision]=internal_error
                    WorkingPhaseRun[FailureCode]=80
                else
                    WorkingPhaseRun[FailureDecision]=validation_error
                    WorkingPhaseRun[FailureCode]=71
                fi
                return 1
            fi
        done
    fi

    archive_before_build_hook "$DeviceId" "$DeviceDirectory" "$WorkingPath"
    archive_sources_match_selection \
        "$PathsName" "$DevicesName" "$InodesName" "$DigestsName" || Status=$?
    if (( Status != 0 )); then
        WorkingPhaseRun[FailureDisposition]=finish
        if (( Status == 80 )); then
            WorkingPhaseRun[FailureDecision]=internal_error
            WorkingPhaseRun[FailureCode]=80
        else
            WorkingPhaseRun[FailureDecision]=create_error
            WorkingPhaseRun[FailureCode]=70
        fi
        return 1
    fi
    # shellcheck disable=SC2034  # WorkingUpdatePaths is consumed through a named-array seam.
    WorkingUpdatePaths=("${ArchiveOriginalPaths[@]}")
    prepare_batch_archive_log_input \
        "$ContextName" "$PathsName" WorkingUpdatePaths || Status=$?
    if (( Status != 0 )); then
        WorkspaceStatus=0
        cleanup_archive_log_workspace "$ContextName" || WorkspaceStatus=$?
        WorkingPhaseRun[FailureDisposition]=finish
        case "$Status" in
            1)
                WorkingPhaseRun[FailureDecision]=validation_error
                WorkingPhaseRun[FailureCode]=71
                ;;
            35)
                classify_active_artifact_storage_failure || StorageCode=$?
                (( StorageCode != 0 )) || StorageCode=80
                WorkingPhaseRun[FailureDecision]=storage_failure
                WorkingPhaseRun[FailureCode]="$StorageCode"
                ;;
            *)
                WorkingPhaseRun[FailureDecision]=internal_error
                WorkingPhaseRun[FailureCode]=80
                ;;
        esac
        : "$WorkspaceStatus"
        return 1
    fi
    update_working_archive "$WorkingPath" WorkingUpdatePaths || Status=$?
    refresh_owned_archive_file "$WorkingPath" "$WorkingEntry" || RefreshStatus=$?
    cleanup_archive_log_workspace "$ContextName" || WorkspaceStatus=$?
    if (( Status != 0 || RefreshStatus != 0 )); then
        WorkingPhaseRun[FailureDisposition]=finish
        WorkingPhaseRun[FailureDecision]=create_error
        WorkingPhaseRun[FailureCode]=70
        return 1
    fi
    if (( WorkspaceStatus != 0 )); then
        WorkingPhaseRun[FailureDisposition]=finish
        if (( WorkspaceStatus == 80 )); then
            WorkingPhaseRun[FailureDecision]=internal_error
            WorkingPhaseRun[FailureCode]=80
        else
            classify_active_artifact_storage_failure || StorageCode=$?
            (( StorageCode != 0 )) || StorageCode=80
            WorkingPhaseRun[FailureDecision]=storage_failure
            WorkingPhaseRun[FailureCode]="$StorageCode"
        fi
        return 1
    fi
    archive_sources_match_selection \
        "$PathsName" "$DevicesName" "$InodesName" "$DigestsName" || Status=$?
    if (( Status != 0 )); then
        WorkingPhaseRun[FailureDisposition]=finish
        if (( Status == 80 )); then
            WorkingPhaseRun[FailureDecision]=internal_error
            WorkingPhaseRun[FailureCode]=80
        else
            WorkingPhaseRun[FailureDecision]=create_error
            WorkingPhaseRun[FailureCode]=70
        fi
        return 1
    fi
    if ! validate_zip_archive "$WorkingPath"; then
        WorkingPhaseRun[FailureDisposition]=finish
        WorkingPhaseRun[FailureDecision]=validation_error
        WorkingPhaseRun[FailureCode]=71
        return 1
    fi
    append_archive_trace "$DeviceId:working_valid:${WorkingPath}"
    return 0
}

# Назначение: Повторно сверяет sources/target и атомарно публикует доказанно валидный staging ZIP.
publish_monthly_archive_staging_phase()
{
    local ContextName="$1"
    # shellcheck disable=SC2178  # The nameref target is the caller's associative context.
    local -n PublishPhaseRun="$ContextName"
    local DeviceId="${PublishPhaseRun[DeviceId]}"
    local TargetDirectory="${PublishPhaseRun[TargetDirectory]:-${PublishPhaseRun[DeviceDirectory]}}"
    local TargetPath="${PublishPhaseRun[TargetPath]}"
    local TargetState="${PublishPhaseRun[TargetState]}"
    local TargetDevice="${PublishPhaseRun[TargetDevice]}"
    local TargetInode="${PublishPhaseRun[TargetInode]}"
    local WorkingPath="${PublishPhaseRun[WorkingPath]}"
    local -n StagingPath="${ContextName}[StagingPath]"
    local -n StagingEntry="${ContextName}[StagingEntry]"
    local -n StagingDevice="${ContextName}[StagingDevice]"
    local -n StagingInode="${ContextName}[StagingInode]"
    local Status=0
    local DeferralStatus=0
    local StorageCode=0

    create_owned_archive_file "$TargetDirectory" staging StagingPath StagingEntry || Status=$?
    if (( Status != 0 )); then
        PublishPhaseRun[FailureDisposition]=finish
        if (( Status == 80 )); then
            PublishPhaseRun[FailureDecision]=internal_error
            PublishPhaseRun[FailureCode]=80
        else
            classify_active_artifact_storage_failure || StorageCode=$?
            (( StorageCode != 0 )) || StorageCode=80
            PublishPhaseRun[FailureDecision]=storage_failure
            PublishPhaseRun[FailureCode]="$StorageCode"
        fi
        return 1
    fi
    copy_archive_file "$WorkingPath" "$StagingPath" || Status=$?
    if (( Status != 0 )) || ! cleanup_entry_matches_path "$StagingEntry"; then
        classify_active_artifact_storage_failure || StorageCode=$?
        (( StorageCode != 0 )) || StorageCode=80
        PublishPhaseRun[FailureDisposition]=finish
        PublishPhaseRun[FailureDecision]=storage_failure
        PublishPhaseRun[FailureCode]="$StorageCode"
        return 1
    fi
    if ! validate_zip_archive "$StagingPath"; then
        PublishPhaseRun[FailureDisposition]=finish
        PublishPhaseRun[FailureDecision]=validation_error
        PublishPhaseRun[FailureCode]=71
        return 1
    fi
    if ! cleanup_entry_matches_path "$StagingEntry"; then
        PublishPhaseRun[FailureDisposition]=finish
        PublishPhaseRun[FailureDecision]=validation_error
        PublishPhaseRun[FailureCode]=71
        return 1
    fi
    local -n StagingCleanupContext="$StagingEntry"
    StagingDevice="${StagingCleanupContext[Device]}"
    StagingInode="${StagingCleanupContext[Inode]}"
    append_archive_trace "$DeviceId:staging_valid:${StagingPath##*/}"

    archive_before_target_recheck_hook "$DeviceId" "$TargetPath" "$StagingPath"
    if ! archive_target_matches_snapshot \
        "$TargetPath" "$TargetState" "$TargetDevice" "$TargetInode"; then
        PublishPhaseRun[FailureDisposition]=finish
        PublishPhaseRun[FailureDecision]=validation_error
        PublishPhaseRun[FailureCode]=71
        return 1
    fi
    archive_before_publish_hook "$DeviceId" "$TargetPath" "$StagingPath"
    begin_signal_deferral || DeferralStatus=$?
    if (( DeferralStatus != 0 )); then
        Status="$DeferralStatus"
    elif [[ "$TargetState" == absent ]]; then
        publish_archive_staging_if_absent "$StagingPath" "$TargetPath" || Status=$?
        if (( Status == 0 )) &&
           { ! archive_regular_path_matches_identity \
                   "$TargetPath" "$StagingDevice" "$StagingInode" ||
             ! archive_regular_path_matches_identity \
                   "$StagingPath" "$StagingDevice" "$StagingInode"; }; then
            Status=80
        fi
        if (( Status == 0 )); then
            remove_owned_archive_file "$StagingPath" "$StagingEntry" || Status=$?
            (( Status == 0 )) && StagingEntry=''
        fi
    else
        publish_archive_staging "$StagingPath" "$TargetPath" || Status=$?
        if (( Status == 0 )); then
            close_archive_reference_fd "$StagingEntry" || Status=$?
        fi
        if (( Status == 0 )); then
            # shellcheck disable=SC2178  # The dynamic cleanup entry is associative.
            local -n PublishedStagingEntry="$StagingEntry"
            # shellcheck disable=SC2034  # The cleanup registry consumes the updated entry.
            PublishedStagingEntry[Value]="$TargetPath"
            cleanup_entry_matches_path "$StagingEntry" || Status=$?
        fi
        if (( Status == 0 )); then
            unregister_cleanup_entry "$StagingEntry" || Status=$?
            (( Status == 0 )) && StagingEntry=''
        fi
    fi
    end_signal_deferral || DeferralStatus=$?
    (( DeferralStatus == 0 )) || Status="$DeferralStatus"
    if (( Status != 0 )); then
        if (( Status == 80 )); then
            StorageCode=80
        elif [[ -e "$TargetPath" || -L "$TargetPath" ]] &&
             ! archive_regular_path_matches_identity \
                 "$TargetPath" "$StagingDevice" "$StagingInode"; then
            StorageCode=71
        else
            classify_active_artifact_storage_failure || StorageCode=$?
            (( StorageCode != 0 )) || StorageCode=80
        fi
        PublishPhaseRun[FailureDisposition]=finish
        PublishPhaseRun[FailureCode]="$StorageCode"
        if (( StorageCode == 71 )); then
            PublishPhaseRun[FailureDecision]=validation_error
        else
            PublishPhaseRun[FailureDecision]=storage_failure
        fi
        return 1
    fi
    append_archive_trace "$DeviceId:installed:${TargetPath##*/}"
    return 0
}

# Назначение: После публикации закрывает временные ресурсы, retire-ит неизменившиеся sources с device-log последним и фиксирует archive outcome.
finalize_monthly_archive_success_phase()
{
    local ContextName="$1"
    local PathsName="$2"
    local DevicesName="$3"
    local InodesName="$4"
    local DigestsName="$5"
    # shellcheck disable=SC2178  # The nameref target is the caller's associative context.
    local -n FinalizePhaseRun="$ContextName"
    local DeviceId="${FinalizePhaseRun[DeviceId]}"
    local TargetPath="${FinalizePhaseRun[TargetPath]}"
    local DeviceJournalPath="${FinalizePhaseRun[DeviceJournalPath]:-}"
    local -n TargetReferenceFd="${ContextName}[TargetReferenceFd]"
    local -n TargetReferenceCleanup="${ContextName}[TargetReferenceCleanup]"
    local -n WorkingPath="${ContextName}[WorkingPath]"
    local -n WorkingEntry="${ContextName}[WorkingEntry]"
    local Status=0
    local CleanupStatus=0
    local Result=0

    if [[ -n "$TargetReferenceFd" || -n "$TargetReferenceCleanup" ]]; then
        close_archive_target_reference \
            "$TargetReferenceFd" "$TargetReferenceCleanup" || Status=$?
        if (( Status != 0 )); then
            Result=80
        else
            TargetReferenceFd=''
            TargetReferenceCleanup=''
        fi
    fi

    remove_owned_archive_file "$WorkingPath" "$WorkingEntry" || CleanupStatus=$?
    WorkingEntry=''
    if (( CleanupStatus != 0 )); then
        if (( CleanupStatus == 80 )); then
            Result=80
        else
            classify_active_artifact_storage_failure || Result=$?
            (( Result != 0 )) || Result=80
        fi
    fi
    archive_before_source_cleanup_hook "$DeviceId" "$TargetPath"
    if ! pipeline_stop_code "$Result"; then
        Status=0
        remove_selected_archive_sources "$DeviceId" \
            "$PathsName" "$DevicesName" "$InodesName" "$DigestsName" \
            "$DeviceJournalPath" || Status=$?
        select_stronger_result "$Result" "$Status" Result
    fi
    if (( Result == 0 )); then
        RunState["${DeviceId}.ArchiveDecision"]=installed
    else
        RunState["${DeviceId}.ArchiveDecision"]=installed_cleanup_failed
    fi
    RunState["${DeviceId}.ArchiveCode"]="$Result"
    append_archive_trace "$DeviceId:${RunState["${DeviceId}.ArchiveDecision"]}:result:$Result"
    return "$Result"
}

# Назначение: Оркестрирует безопасные архивные фазы одного устройства и не допускает retirement до проверенной публикации.
run_monthly_archive_for_device()
{
    local DeviceId="$1"
    local DeviceDirectory="$2"
    local Status=0
    local StorageCode=0
    local -A ArchiveRun=(
        [DeviceId]="$DeviceId"
        [DeviceDirectory]="$DeviceDirectory"
        [DeviceJournalPath]=''
        [ArchiveLabel]=''
        [TargetDirectory]=''
        [TargetPath]=''
        [TargetState]=''
        [TargetDevice]=''
        [TargetInode]=''
        [TargetReferenceFd]=''
        [TargetReferencePath]=''
        [TargetReferenceCleanup]=''
        [WorkingPath]=''
        [WorkingEntry]=''
        [StagingPath]=''
        [StagingEntry]=''
        [StagingDevice]=''
        [StagingInode]=''
        [LogWorkspaceDirectory]=''
        [LogWorkspaceDirectoryEntry]=''
        [LogWorkspaceFileEntry]=''
        [LogMergedPath]=''
        [LogMemberCount]=''
        [LogOverlap]=''
        [FailureDisposition]=''
        [FailureDecision]=''
        [FailureCode]=''
    )
    local -n TargetPath='ArchiveRun[TargetPath]'
    local -n TargetDirectory='ArchiveRun[TargetDirectory]'
    local -n TargetReferenceFd='ArchiveRun[TargetReferenceFd]'
    local -n TargetReferenceCleanup='ArchiveRun[TargetReferenceCleanup]'
    local -n WorkingPath='ArchiveRun[WorkingPath]'
    local -n WorkingEntry='ArchiveRun[WorkingEntry]'
    local -n StagingPath='ArchiveRun[StagingPath]'
    local -n StagingEntry='ArchiveRun[StagingEntry]'
    local -a SelectedPaths=()
    # shellcheck disable=SC2034  # Populated and consumed through named-array seams.
    local -a SelectedDevices=()
    # shellcheck disable=SC2034  # Populated and consumed through named-array seams.
    local -a SelectedInodes=()
    # shellcheck disable=SC2034  # Populated and consumed through named-array seams.
    local -a SelectedDigests=()

    [[ "$DeviceId" =~ ^DeviceContext_[1-9][0-9]*$ &&
       -d "$DeviceDirectory" && ! -L "$DeviceDirectory" ]] || return 80
    [[ "${RuntimeState[MonthlyArchiveDue]:-false}" == true ]] || return 0
    device_context_exists "$DeviceId" || return 80
    local -n ArchiveDeviceContext="$DeviceId"
    [[ "${StorageContext[Prepared]:-false}" == true &&
       "${LockContext[RootHeld]:-false}" == true &&
       "${ArchiveDeviceContext[PreparedDirectory]:-}" == "$DeviceDirectory" ]] || return 80
    case "${ExecutionState[RunMode]:-}" in
        batch)
            [[ "${LockContext[RootMode]:-}" == exclusive ]] || return 80
            ;;
        single)
            [[ "${LockContext[RootMode]:-}" == shared &&
               "${LockContext[DeviceHeld]:-false}" == true ]] || return 80
            ;;
        *) return 80 ;;
    esac
    [[ "${RuntimeState[MonthlyArchiveLabel]:-}" =~ ^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[0-2])\.[0-9]{4}$ ]] || return 80
    ArchiveRun[ArchiveLabel]="${RuntimeState[MonthlyArchiveLabel]}"
    if [[ "${ExecutionState[RunMode]}" == batch ]]; then
        TargetDirectory="$DeviceDirectory/archive"
    else
        TargetDirectory="$DeviceDirectory"
    fi
    TargetPath="$TargetDirectory/${ArchiveRun[ArchiveLabel]}.zip"
    discover_archive_sources "$DeviceDirectory" \
        SelectedPaths SelectedDevices SelectedInodes SelectedDigests "$DeviceId" \
        'ArchiveRun[DeviceJournalPath]' || Status=$?
    if (( Status != 0 )); then
        (( Status == 80 )) && return 80
        classify_active_artifact_storage_failure || StorageCode=$?
        (( StorageCode != 0 )) || StorageCode=80
        finish_archive_failure "$DeviceId" storage_failure "$StorageCode" '' '' '' ''
        return $?
    fi
    RunState["${DeviceId}.ArchiveSourceCount"]="${#SelectedPaths[@]}"
    RunState["${DeviceId}.ArchiveTarget"]="${TargetPath##*/}"
    if (( ${#SelectedPaths[@]} == 0 )); then
        RunState["${DeviceId}.ArchiveDecision"]=no_sources
        RunState["${DeviceId}.ArchiveCode"]=0
        append_archive_trace "$DeviceId:no_sources"
        return 0
    fi
    Status=0
    ArchiveRun[FailureDisposition]=''
    ArchiveRun[FailureDecision]=''
    ArchiveRun[FailureCode]=''
    prepare_monthly_archive_target_phase ArchiveRun || Status=$?
    if (( Status == 0 )); then
        Status=0
        ArchiveRun[FailureDisposition]=''
        ArchiveRun[FailureDecision]=''
        ArchiveRun[FailureCode]=''
        build_monthly_archive_working_phase ArchiveRun \
            SelectedPaths SelectedDevices SelectedInodes SelectedDigests || Status=$?
    fi
    if (( Status == 0 )); then
        Status=0
        ArchiveRun[FailureDisposition]=''
        ArchiveRun[FailureDecision]=''
        ArchiveRun[FailureCode]=''
        publish_monthly_archive_staging_phase ArchiveRun || Status=$?
    fi
    if (( Status != 0 )); then
        if [[ "${ArchiveRun[FailureDisposition]}" == direct ]]; then
            return "${ArchiveRun[FailureCode]}"
        fi
        [[ "${ArchiveRun[FailureDisposition]}" == finish &&
           -n "${ArchiveRun[FailureDecision]}" &&
           -n "${ArchiveRun[FailureCode]}" ]] || return 80
        finish_archive_failure \
            "$DeviceId" "${ArchiveRun[FailureDecision]}" "${ArchiveRun[FailureCode]}" \
            "$WorkingPath" "$WorkingEntry" "$StagingPath" "$StagingEntry" \
            "$TargetReferenceFd" "$TargetReferenceCleanup"
        return $?
    fi
    Status=0
    ArchiveRun[FailureDisposition]=''
    ArchiveRun[FailureDecision]=''
    ArchiveRun[FailureCode]=''
    finalize_monthly_archive_success_phase ArchiveRun \
        SelectedPaths SelectedDevices SelectedInodes SelectedDigests
}

# ==============================================================================
# Per-device backup orchestration and dependency gates
# ==============================================================================

# Назначение: Открывает password channel и проверяет transport-поля устройства непосредственно перед сетевыми операциями.
# shellcheck disable=SC2034  # Claimed outputs use namerefs.
prepare_device_transport_context()
{
    local DeviceId="$1"
    local -n ClaimedNameOut="$2"
    local -n PreparedDirectoryOut="$3"
    local LiveIdentity=''
    local Status=0

    ClaimedNameOut=''
    PreparedDirectoryOut=''
    validate_device_transport_context "$DeviceId" || return 80
    [[ "${StorageContext[Prepared]:-false}" == true &&
       "${LockContext[RootHeld]:-false}" == true ]] || return 80
    if [[ "${EffectiveConfig[UseIdentityName]:-true}" == true ]]; then
        mikrotik_get_identity "$DeviceId" LiveIdentity || Status=$?
        (( Status == 0 )) || return "$Status"
        prepare_identity_device_name "$DeviceId" "$LiveIdentity" || return $?
    elif [[ "${EffectiveConfig[UseIdentityName]:-true}" == false ]]; then
        prepare_declared_device_name "$DeviceId" || return $?
    else
        return 80
    fi

    local -n PreparedTransportDevice="$DeviceId"
    ClaimedNameOut="${PreparedTransportDevice[DeviceName]}"
    if [[ "${ExecutionState[RunMode]:-}" == single ]]; then
        acquire_device_lock "$ClaimedNameOut" || return $?
        append_transport_trace device_lock
        verify_common_root_invariants 36 || return $?
        PreparedDirectoryOut="${StorageContext[CanonicalRoot]}"
        append_transport_trace device_directory
    elif [[ "${ExecutionState[RunMode]:-}" == batch ]]; then
        prepare_device_directory "$ClaimedNameOut" PreparedDirectoryOut || return $?
        append_transport_trace device_directory
    else
        return 80
    fi
    PreparedTransportDevice["PreparedDirectory"]="$PreparedDirectoryOut"
    return 0
}

# Назначение: Создаёт общий DeviceContext из полного CLI single-набора, чтобы использовать тот же pipeline, что и batch.
materialize_single_device_context()
{
    [[ "${ExecutionState[RunMode]:-}" == single && ${#DeviceIds[@]} -eq 0 ]] || return 80
    resolve_device_record \
        "${EffectiveConfig[DeviceName]:-${EffectiveConfig[Address]}}" "${EffectiveConfig[Address]}" \
        "${EffectiveConfig[User]}" "${EffectiveConfig[DevicePassword]}" \
        "${EffectiveConfig[SshPort]}" MikroTik cli 0 || return 80
    [[ ${#DeviceIds[@]} -eq 1 ]] || return 80
    return 0
}

# Назначение: Выполняет настроенные DNS/history действия перед binary backup и сохраняет их результат в общем outcome.
run_binary_pre_backup_cleanup()
{
    local DeviceId="$1"
    local Status=0
    local Result=0
    local StepStateKey="DeviceSubeventNumber:$DeviceId"
    local StepNumber=0

    if [[ "${EffectiveConfig[clear_dns_cache]:-true}" == true ]]; then
        StepNumber="${LoggingState[$StepStateKey]:-0}"
        StepNumber=$((StepNumber + 1))
        LoggingState["$StepStateKey"]="$StepNumber"
        emit_runtime_log_event shell device subevent full "$DeviceId" \
            log_device_clear_dns_cache '' ordinary "$StepNumber" none \
            none '' '' '' '' device_main || :
        mikrotik_flush_dns_cache "$DeviceId" || Status=$?
        if (( Status != 0 )); then
            emit_runtime_log_event shell device subevent error "$DeviceId" \
                log_device_clear_dns_cache "$Status" error "$StepNumber" none \
                none '' '' '' '' device_main || :
        fi
        select_stronger_result "$Result" "$Status" Result
        if pipeline_stop_code "$Status"; then
            RunState[StopRun]=true
            return "$Result"
        fi
    fi
    Status=0
    if [[ "${EffectiveConfig[clear_console_history]:-true}" == true ]]; then
        StepNumber="${LoggingState[$StepStateKey]:-0}"
        StepNumber=$((StepNumber + 1))
        LoggingState["$StepStateKey"]="$StepNumber"
        emit_runtime_log_event shell device subevent full "$DeviceId" \
            log_device_clear_console_history '' ordinary "$StepNumber" none \
            none '' '' '' '' device_main || :
        mikrotik_clear_console_history "$DeviceId" || Status=$?
        if (( Status != 0 )); then
            emit_runtime_log_event shell device subevent error "$DeviceId" \
                log_device_clear_console_history "$Status" error "$StepNumber" none \
                none '' '' '' '' device_main || :
        fi
        select_stronger_result "$Result" "$Status" Result
        if pipeline_stop_code "$Status"; then
            RunState[StopRun]=true
            return "$Result"
        fi
    fi
    return "$Result"
}

# Назначение: Переводит stop-код фазы в RunState, чтобы следующие форматы и устройства больше не запускались.
record_run_stop_from_status()
{
    local Status="$1"

    if pipeline_stop_code "$Status"; then
        RunState[StopRun]=true
    fi
    return 0
}

# Назначение: Запускает архивирование только для due batch после locks и до нового backup, отражая outcome и stop policy.
run_due_monthly_archive_pipeline()
{
    local DeviceId="$1"
    local DeviceDirectory="$2"
    local SourcesAvailable=false
    local AvailabilityStatus=0
    local ArchiveStatus=0

    [[ "${RuntimeState[MonthlyArchiveDue]:-false}" == true ]] || return 0
    archive_sources_available \
        "$DeviceDirectory" "$DeviceId" SourcesAvailable || AvailabilityStatus=$?
    if (( AvailabilityStatus == 0 )) && [[ "$SourcesAvailable" == false ]]; then
        RunState["${DeviceId}.ArchiveSourceCount"]=0
        RunState["${DeviceId}.ArchiveTarget"]="${RuntimeState[MonthlyArchiveLabel]}.zip"
        RunState["${DeviceId}.ArchiveDecision"]=no_sources
        RunState["${DeviceId}.ArchiveCode"]=0
        append_archive_trace "$DeviceId:no_sources"
        return 0
    fi

    emit_runtime_log_event shell device main short "$DeviceId" \
        log_device_monthly_archive '' start '' block \
        none '' '' '' '' device_main || :
    run_monthly_archive_for_device "$DeviceId" "$DeviceDirectory" || ArchiveStatus=$?
    emit_runtime_log_event shell device main short "$DeviceId" \
        log_device_monthly_archive "$ArchiveStatus" outcome '' none \
        none '' '' '' '' device_main || :
    return "$ArchiveStatus"
}

# Назначение: Оркестрирует identity, каталог, архивную фазу, форматы backup и incremental cleanup одного устройства.
run_device_backup_pipeline()
{
    local DeviceId="$1"
    local DeviceName=''
    local DeviceDirectory=''
    local Timestamp=''
    local RemoteStem=''
    local RemoteName=''
    local LocalPath=''
    local Format=''
    local Status=0
    local DeviceResult=0
    local ArchiveStatus=0
    local MainResult=0
    local MainMessageKey=''
    local MainBoundary=none
    local MainIndex=0
    local StepStateKey="DeviceSubeventNumber:$DeviceId"
    local StepNumber=0
    local WarningCountBefore=0
    local -a Formats=()

    prepare_device_transport_context "$DeviceId" DeviceName DeviceDirectory || Status=$?
    if (( Status != 0 )); then
        record_run_stop_from_status "$Status"
        return "$Status"
    fi
    if [[ "${ExecutionState[RunMode]:-}" == batch ]]; then
        emit_runtime_log_event shell script main short '' log_batch_device \
            '' start '' "${LoggingState[BatchDeviceBoundary]:-none}" \
            batch_device "${LoggingState[BatchDeviceIndex]:-}" \
            "${LoggingState[BatchDeviceTotal]:-}" "$DeviceName" '' \
            batch_child || :
        LoggingState[BatchDeviceStarted]=true
    fi
    begin_device_journal_pass "$DeviceId" || :
    if [[ "${ExecutionState[RunMode]:-}" == batch ]]; then
        ArchiveStatus=0
        run_due_monthly_archive_pipeline "$DeviceId" "$DeviceDirectory" || ArchiveStatus=$?
        select_stronger_result "$DeviceResult" "$ArchiveStatus" DeviceResult
        record_run_stop_from_status "$ArchiveStatus"
        if pipeline_stop_code "$ArchiveStatus"; then
            return "$DeviceResult"
        fi
    fi

    Status=0
    capture_backup_timestamp Timestamp || Status=$?
    if (( Status != 0 )); then
        select_stronger_result "$DeviceResult" "$Status" DeviceResult
        record_run_stop_from_status "$Status"
        return "$DeviceResult"
    fi
    # The dynamic device context persists the one timestamp and remote stem.
    # shellcheck disable=SC2034
    local -n BackupDeviceContext="$DeviceId"
    BackupDeviceContext["BackupTimestamp"]="$Timestamp"
    build_remote_backup_stem "$DeviceId" "$Timestamp" RemoteStem || Status=$?
    if (( Status != 0 )); then
        select_stronger_result "$DeviceResult" "$Status" DeviceResult
        record_run_stop_from_status "$Status"
        return "$DeviceResult"
    fi
    BackupDeviceContext["RemoteBackupStem"]="$RemoteStem"
    append_backup_trace \
        "$DeviceId:timestamp:${BackupDeviceContext[BackupTimestamp]}:stem:${BackupDeviceContext[RemoteBackupStem]}"
    emit_runtime_log_event shell device grouping short "$DeviceId" \
        log_device_group '' ordinary '' none device_name "$DeviceName" '' '' '' \
        device_group || :

    case "${EffectiveConfig[backup_type]:-both}" in
        configuration) Formats=(rsc) ;;
        binary) Formats=(backup) ;;
        both) Formats=(rsc backup) ;;
        *)
            Status=80
            select_stronger_result "$DeviceResult" "$Status" DeviceResult
            record_run_stop_from_status "$Status"
            return "$DeviceResult"
            ;;
    esac

    for Format in "${Formats[@]}"; do
        MainIndex=$((MainIndex + 1))
        MainBoundary=none
        (( MainIndex > 1 )) && MainBoundary=block
        MainResult=0
        LoggingState["$StepStateKey"]=0
        case "$Format" in
            rsc) MainMessageKey=log_device_rsc_backup ;;
            backup) MainMessageKey=log_device_binary_backup ;;
            *)
                Status=80
                select_stronger_result "$DeviceResult" "$Status" DeviceResult
                record_run_stop_from_status "$Status"
                return "$DeviceResult"
                ;;
        esac
        emit_runtime_log_event shell device main short "$DeviceId" \
            "$MainMessageKey" '' start '' "$MainBoundary" \
            none '' '' '' '' device_main || :
        if [[ "$Format" == backup ]]; then
            Status=0
            run_binary_pre_backup_cleanup "$DeviceId" || Status=$?
            MainResult="$Status"
            select_stronger_result "$DeviceResult" "$Status" DeviceResult
            record_run_stop_from_status "$Status"
            if pipeline_stop_code "$Status"; then
                emit_runtime_log_event shell device main short "$DeviceId" \
                    "$MainMessageKey" "$MainResult" outcome '' none \
                    none '' '' '' '' device_main || :
                unset 'LoggingState['"$StepStateKey"']'
                return "$DeviceResult"
            fi
            Status=0
        fi
        RemoteName="$RemoteStem.$Format"
        StepNumber="${LoggingState[$StepStateKey]:-0}"
        StepNumber=$((StepNumber + 1))
        LoggingState["$StepStateKey"]="$StepNumber"
        emit_runtime_log_event shell device subevent full "$DeviceId" \
            log_device_build_local_path '' ordinary "$StepNumber" none \
            none '' '' '' '' device_main || :
        build_local_artifact_path "$DeviceName" "$Timestamp" "$Format" \
            "$DeviceDirectory" LocalPath || Status=$?
        if (( Status != 0 )); then
            emit_runtime_log_event shell device subevent error "$DeviceId" \
                log_device_build_local_path "$Status" error "$StepNumber" none \
                none '' '' '' '' device_main || :
        fi
        if (( Status == 0 )); then
            run_backup_format_pipeline \
                "$DeviceId" "$Format" "$RemoteStem" "$RemoteName" "$LocalPath" || Status=$?
        fi
        if (( Status == 0 )) && [[ "${EffectiveConfig[UseIncremental]:-true}" == true ]]; then
            StepNumber="${LoggingState[$StepStateKey]:-0}"
            StepNumber=$((StepNumber + 1))
            LoggingState["$StepStateKey"]="$StepNumber"
            emit_runtime_log_event shell device subevent full "$DeviceId" \
                log_device_incremental_compare '' ordinary "$StepNumber" none \
                none '' '' '' '' device_main || :
            WarningCountBefore="${RuntimeState[WarningCount]:-0}"
            run_incremental_comparison \
                "$DeviceId" "$DeviceName" "$Timestamp" "$Format" "$LocalPath" || Status=$?
            if (( Status != 0 )); then
                emit_runtime_log_event shell device subevent error "$DeviceId" \
                    log_device_incremental_compare "$Status" error "$StepNumber" none \
                    none '' '' '' '' device_main || :
                RunState["${DeviceId}.${Format}.Result"]="$Status"
            elif (( ${RuntimeState[WarningCount]:-0} > WarningCountBefore )); then
                emit_runtime_log_event shell device subevent error "$DeviceId" \
                    log_device_incremental_compare 1 error "$StepNumber" none \
                    none '' '' '' '' device_main || :
            fi
        elif (( Status == 0 )); then
            RunState["${DeviceId}.${Format}.PreviousArtifact"]=''
            RunState["${DeviceId}.${Format}.IncrementalDecision"]=disabled
            append_incremental_trace "$DeviceId:$Format:disabled"
        fi
        select_stronger_result "$MainResult" "$Status" MainResult
        select_stronger_result "$DeviceResult" "$Status" DeviceResult
        emit_runtime_log_event shell device main short "$DeviceId" \
            "$MainMessageKey" "$MainResult" outcome '' none \
            none '' '' '' '' device_main || :
        unset 'LoggingState['"$StepStateKey"']'
        record_run_stop_from_status "$Status"
        if pipeline_stop_code "$Status"; then
            return "$DeviceResult"
        fi
        Status=0
    done
    if [[ "${ExecutionState[RunMode]:-}" == single ]]; then
        ArchiveStatus=0
        run_due_monthly_archive_pipeline "$DeviceId" "$DeviceDirectory" || ArchiveStatus=$?
        select_stronger_result "$DeviceResult" "$ArchiveStatus" DeviceResult
        record_run_stop_from_status "$ArchiveStatus"
    fi
    return "$DeviceResult"
}

# Назначение: Последовательно обрабатывает single либо коллекцию batch-устройств, соблюдая stop-состояние и итоговую агрегацию.
dispatch_backup_pipeline()
{
    local DeviceId
    local Status=0
    local BatchFailureCode=0
    local BatchLogResult=0
    local DeviceIndex=0
    local DeviceTotal=0
    local DeviceLogResult=0
    local DeviceMessageKey=''
    local DeviceName=''
    local FailureMessageKey=''
    local Boundary=none

    RunState[StopRun]=false
    RunState[ProcessedDevices]=0
    if [[ "${ExecutionState[RunMode]:-}" == single ]]; then
        materialize_single_device_context || return $?
    elif [[ "${ExecutionState[RunMode]:-}" != batch ]]; then
        return 80
    fi
    (( ${#DeviceIds[@]} > 0 )) || return 80
    if [[ "${ExecutionState[RunMode]:-}" == batch ]]; then
        DeviceTotal="${#DeviceIds[@]}"
        emit_runtime_log_event shell script main short '' log_batch_processing \
            '' start '' none none '' '' '' '' batch_parent || :
    fi
    for DeviceId in "${DeviceIds[@]}"; do
        DeviceIndex=$((DeviceIndex + 1))
        Boundary=none
        (( DeviceIndex > 1 )) && Boundary=block
        LoggingState[BatchDeviceIndex]="$DeviceIndex"
        LoggingState[BatchDeviceTotal]="$DeviceTotal"
        LoggingState[BatchDeviceBoundary]="$Boundary"
        LoggingState[BatchDeviceStarted]=false
        Status=0
        run_device_backup_pipeline "$DeviceId" || Status=$?
        if [[ "${ExecutionState[RunMode]:-}" == batch ]]; then
            DeviceMessageKey=log_batch_device_position
            DeviceName=''
            if [[ "${LoggingState[BatchDeviceStarted]:-false}" == true ]]; then
                local -n LoggedBatchDevice="$DeviceId"
                DeviceName="${LoggedBatchDevice[DeviceName]:-}"
                DeviceMessageKey=log_batch_device
            else
                emit_runtime_log_event shell script main short '' \
                    "$DeviceMessageKey" '' start '' "$Boundary" \
                    batch_device "$DeviceIndex" "$DeviceTotal" '' '' \
                    batch_child || :
            fi
            DeviceLogResult=0
            if (( Status != 0 && Status != 1 )); then
                DeviceLogResult="$Status"
                run_result_message_key "$Status" FailureMessageKey || \
                    FailureMessageKey=result_unknown_failure
                emit_runtime_log_event shell script context error '' \
                    "$FailureMessageKey" "$Status" error '' none \
                    none '' '' '' '' batch_child || :
                select_stronger_result "$BatchFailureCode" "$Status" BatchFailureCode
            fi
            emit_runtime_log_event shell script main short '' "$DeviceMessageKey" \
                "$DeviceLogResult" outcome '' none batch_device "$DeviceIndex" \
                "$DeviceTotal" "$DeviceName" '' batch_child || :
        fi
        RunState[ProcessedDevices]=$((RunState[ProcessedDevices] + 1))
        promote_run_result "$Status"
        if pipeline_stop_code "$Status" || [[ "${RunState[StopRun]:-false}" == true ||
              "${StorageContext[StopBatch]:-false}" == true ]]; then
            RunState[StopRun]=true
            if [[ "${ExecutionState[RunMode]:-}" == batch ]]; then
                BatchLogResult="$BatchFailureCode"
                emit_runtime_log_event shell script main short '' \
                    log_batch_processing "$BatchLogResult" outcome '' none \
                    none '' '' '' '' batch_parent || :
            fi
            return "$Status"
        fi
    done
    if [[ "${ExecutionState[RunMode]:-}" == batch ]]; then
        BatchLogResult="$BatchFailureCode"
        emit_runtime_log_event shell script main short '' log_batch_processing \
            "$BatchLogResult" outcome '' none none '' '' '' '' batch_parent || :
    fi
    return 0
}

# Назначение: Строит точный набор обязательных утилит по run mode, storage и признаку MonthlyArchive due.
build_dependency_profile()
{
    local Dependency
    DependencyProfile=()

    for Dependency in ssh scp sshpass timeout sleep sha256sum realpath flock; do
        DependencyProfile["$Dependency"]=required
    done
    if [[ "${ExecutionState[RunMode]:-batch}" == batch &&
          "${EffectiveConfig[UseNetFolder]}" == true ]]; then
        DependencyProfile[findmnt]=required
    fi
    if [[ "${RuntimeState[MonthlyArchiveDue]:-false}" == true ]]; then
        DependencyProfile[zip]=required
        DependencyProfile[unzip]=required
        DependencyProfile[mv]=required
    fi
    return 0
}

# Назначение: Проверяет только сформированный dependency profile и возвращает код до начала зависимой работы.
check_dependencies()
{
    local Dependency

    for Dependency in "${!DependencyProfile[@]}"; do
        if ! command -v "$Dependency" >/dev/null 2>&1; then
            # Retained for callers and diagnostics added by later stages.
            # shellcheck disable=SC2034
            ExecutionState[MissingDependency]="$Dependency"
            return 30
        fi
    done
    return 0
}

# ==============================================================================
# Terminal session lifecycle and generic render/input primitives
# ==============================================================================

# Назначение: Сохраняет исходный stty один раз, чтобы любые UI-переходы и сигналы могли восстановить терминал.
capture_terminal_state()
{
    local SavedState=''

    [[ -t 0 && -t 1 ]] || return 31
    SavedState="$(stty -g <&0 2>/dev/null)" || return 31
    [[ -n "$SavedState" ]] || return 31
    RuntimeState[TerminalSavedState]="$SavedState"
    RuntimeState[TerminalStateActive]=false
    RuntimeState[TerminalTransitionPending]=false
    return 0
}

# Назначение: Переводит tty в канонический режим построчного ввода с отображением согласно виду поля.
enter_terminal_input_mode()
{
    local InputMode="$1"
    local SavedState="${RuntimeState[TerminalSavedState]:-}"
    local Status=0

    [[ -n "$SavedState" ]] || return 31
    if [[ "${RuntimeState[TerminalStateActive]:-false}" == true ]]; then
        return 0
    fi
    RuntimeState[TerminalTransitionPending]=true
    case "$InputMode" in
        selection) stty -echo -icanon -ixon -ixoff min 1 time 0 <&0 2>/dev/null || Status=$? ;;
        secret) stty -echo -icanon -ixon -ixoff min 1 time 0 <&0 2>/dev/null || Status=$? ;;
        *) RuntimeState[TerminalTransitionPending]=false; return 80 ;;
    esac
    if (( Status != 0 )); then
        restore_terminal_state || :
        return 31
    fi
    RuntimeState[TerminalStateActive]=true
    RuntimeState[TerminalTransitionPending]=false
    return 0
}

# Назначение: Переводит tty в посимвольный режим навигации без echo для списков выбора.
enter_terminal_selection_mode()
{
    enter_terminal_input_mode selection
}

# Назначение: Переводит tty в посимвольный режим редактирования секрета без отображения введённых символов.
enter_terminal_secret_mode()
{
    enter_terminal_input_mode secret
}

# Назначение: Требует одновременно доступные stdin/stdout `/dev/tty` для запуска интерактивной поверхности.
interactive_tty_available()
{
    [[ -t 0 && -t 1 ]]
}

# Назначение: Фильтрует события для live terminal log по текущему уровню и роли, отдельно от файловых журналов.
terminal_log_event_is_eligible()
{
    local Detail="$1"
    local Kind="$2"
    local ResultCode="$3"
    local Level=''

    if [[ "${LoggingState[UseFallback]:-false}" == true ]]; then
        Level="${DefaultValues[LogLevel]:-2}"
    else
        Level="${EffectiveConfig[LogLevel]:-}"
    fi
    [[ "$Level" =~ ^[0-3]$ ]] || return 80
    if [[ "$Detail" == error || "$Kind" == error ||
          ( -n "$ResultCode" && "$ResultCode" != 0 ) ]]; then
        return 0
    fi
    case "$Level" in
        0) return 1 ;;
        1|2) [[ "$Detail" == short ]] ;;
        3) return 0 ;;
    esac
}

# Назначение: Перерисовывает нижний блок журнала на tty, удаляя ровно ранее опубликованное число строк.
# shellcheck disable=SC2178  # RowsName identifies a caller-owned indexed array.
terminal_log_replace_block()
{
    local RowsName="$1"
    local -n TerminalRowsToWrite="$RowsName"
    local OldCount="${LoggingState[TerminalRows]:-0}"
    local NewCount="${#TerminalRowsToWrite[@]}"
    local Index=0
    local Output=''
    local Sequence=''

    [[ "$OldCount" =~ ^[0-9]+$ ]] || OldCount=0
    if (( OldCount > 0 )); then
        printf -v Sequence '\033[%dA' "$OldCount"
        Output+="$Sequence"
    fi
    for ((Index=0; Index<NewCount; Index++)); do
        Output+=$'\r\033[2K'"${TerminalRowsToWrite[Index]}"$'\n'
    done
    for ((Index=NewCount; Index<OldCount; Index++)); do
        Output+=$'\r\033[2K\n'
    done
    if (( OldCount > NewCount )); then
        printf -v Sequence '\033[%dA' "$((OldCount - NewCount))"
        Output+="$Sequence"
    fi
    [[ -z "$Output" ]] || printf '%s' "$Output" 2>/dev/null || :
    LoggingState[TerminalRows]="$NewCount"
    return 0
}

# Назначение: Рисует кадры индикатора в отдельном дочернем процессе, пока родительская операция активна.
terminal_log_spinner_loop()
{
    local Message="$1"
    local Rows="$2"
    local Index=1
    local TimerPid=''
    local -a Frames=('|' '/' '-' $'\\')

    trap - EXIT
    trap '[[ -z "$TimerPid" ]] || kill -TERM "$TimerPid" 2>/dev/null || :; [[ -z "$TimerPid" ]] || wait "$TimerPid" 2>/dev/null || :; exit 0' HUP INT TERM
    while :; do
        sleep 0.25 &
        TimerPid=$!
        wait "$TimerPid" 2>/dev/null || return 0
        TimerPid=''
        printf '\033[%dA\r\033[2K[%s] %s\033[%dB\r' \
            "$Rows" "${Frames[Index]}" "$Message" "$Rows" 2>/dev/null || exit 0
        Index=$(((Index + 1) % ${#Frames[@]}))
    done
    return 0
}

# Назначение: Останавливает и reap-ит только принадлежащий UI spinner, очищая его runtime-состояние.
stop_terminal_log_spinner()
{
    local SpinnerPid="${LoggingState[TerminalSpinnerPid]:-}"

    if [[ "${LoggingState[TerminalSpinnerActive]:-false}" == true &&
          "$SpinnerPid" =~ ^[1-9][0-9]*$ ]]; then
        kill -TERM "$SpinnerPid" 2>/dev/null || :
        wait "$SpinnerPid" 2>/dev/null || :
    fi
    LoggingState[TerminalSpinnerActive]=false
    LoggingState[TerminalSpinnerPid]=''
    return 0
}

# Назначение: Запускает spinner для активного видимого события после остановки прежнего экземпляра.
start_terminal_log_spinner()
{
    local Message="$1"
    local Rows="$2"
    local PresentationFd=0
    local SpinnerPid=''

    [[ -n "$Message" && "$Message" != *[$'\001'-$'\037'$'\177']* ]] || return 80
    [[ "$Rows" =~ ^[1-9][0-9]*$ ]] || return 80
    stop_terminal_log_spinner
    exec {PresentationFd}>&1 || return 0
    IFS= read -r SpinnerPid < <(
        trap - EXIT
        trap 'exit 0' HUP INT TERM
        printf '%s\n' "$BASHPID"
        exec 1>&"$PresentationFd"
        exec {PresentationFd}>&-
        terminal_log_spinner_loop "$Message" "$Rows"
    ) || SpinnerPid=''
    exec {PresentationFd}>&-
    [[ "$SpinnerPid" =~ ^[1-9][0-9]*$ ]] || return 0
    LoggingState[TerminalSpinnerPid]="$SpinnerPid"
    LoggingState[TerminalSpinnerActive]=true
    return 0
}

# Назначение: Собирает текущие batch/device/error строки и атомарно заменяет отображаемый terminal block.
refresh_terminal_log_block()
{
    local RestartSpinner="${1:-true}"
    local Level="${LoggingState[TerminalLevel]:-}"
    local MainMessage="${LoggingState[TerminalMainMessage]:-}"
    local CurrentSubevent="${LoggingState[TerminalCurrentSubevent]:-}"
    local Index=0
    local Code=''
    local SpinnerIndex=-1
    local SpinnerMessage=''
    local SpinnerRows=0
    local -a Rows=()

    stop_terminal_log_spinner
    if [[ "${LoggingState[TerminalBatchActive]:-false}" == true ]]; then
        if [[ "${LoggingState[TerminalBatchParentVisible]:-false}" == true ]]; then
            SpinnerIndex="${#Rows[@]}"
            SpinnerMessage="${LoggingState[TerminalBatchParentMessage]:-}"
            Rows+=("[|] $SpinnerMessage")
        fi
        Rows+=("${TerminalLogBatchRows[@]}")
        if [[ "${LoggingState[TerminalBatchChildActive]:-false}" == true &&
              "${LoggingState[TerminalBatchChildVisible]:-false}" == true ]]; then
            if (( ${#TerminalLogBatchRows[@]} > 0 )); then
                Rows+=('')
            fi
            SpinnerIndex="${#Rows[@]}"
            SpinnerMessage="${LoggingState[TerminalBatchChildMessage]:-}"
            Rows+=("[|] $SpinnerMessage")
            Rows+=("${TerminalLogDeviceMainRows[@]}")
            if [[ "${LoggingState[TerminalDeviceMainActive]:-false}" == true &&
                  "${LoggingState[TerminalDeviceMainVisible]:-false}" == true ]]; then
                SpinnerIndex="${#Rows[@]}"
                SpinnerMessage="    ${LoggingState[TerminalDeviceMainMessage]:-}"
                Rows+=("[|] $SpinnerMessage")
                for ((Index=0; Index<${#TerminalLogDeviceErrorMessages[@]}; Index++)); do
                    Code="${TerminalLogDeviceErrorCodes[Index]}"
                    [[ -n "$Code" ]] || Code=ER
                    Rows+=("        ${TerminalPalette[LoggingError]}[$Code]${TerminalPalette[Reset]} ${TerminalLogDeviceErrorMessages[Index]}")
                done
                if [[ "$Level" == 3 && -n "$CurrentSubevent" ]]; then
                    Rows+=("$CurrentSubevent")
                fi
            elif [[ "$Level" == 3 && -n "$CurrentSubevent" ]]; then
                Rows+=("$CurrentSubevent")
            fi
        fi
    elif [[ "${LoggingState[TerminalMainVisible]:-false}" == true ]]; then
        SpinnerIndex="${#Rows[@]}"
        SpinnerMessage="$MainMessage"
        Rows+=("[|] $MainMessage")
        if [[ "$Level" == 3 && -n "$CurrentSubevent" ]]; then
            Rows+=("$CurrentSubevent")
        fi
    fi
    for ((Index=0; Index<${#TerminalLogErrorMessages[@]}; Index++)); do
        Code="${TerminalLogErrorCodes[Index]}"
        [[ -n "$Code" ]] || Code=ER
        Rows+=("${TerminalPalette[LoggingError]}[$Code]${TerminalPalette[Reset]} ${TerminalLogErrorMessages[Index]}")
    done
    terminal_log_replace_block Rows
    if [[ "$RestartSpinner" == true && "$SpinnerIndex" =~ ^[0-9]+$ &&
          -n "$SpinnerMessage" ]]; then
        SpinnerRows=$((${#Rows[@]} - SpinnerIndex))
        start_terminal_log_spinner "$SpinnerMessage" "$SpinnerRows" || :
    fi
    return 0
}

# Назначение: Обновляет terminal state machine по семантическому событию и инициирует нужную перерисовку/spinner.
render_terminal_log_event()
{
    local Context="$1"
    local Domain="$2"
    local Role="$3"
    local Detail="$4"
    local DeviceId="$5"
    local MessageKey="$6"
    local ResultCode="$7"
    local Kind="$8"
    local Number="$9"
    local Boundary="${10}"
    local PayloadType="${11:-none}"
    local PayloadOne="${12:-}"
    local PayloadTwo="${13:-}"
    local PayloadThree="${14:-}"
    local PayloadFour="${15:-}"
    local TerminalLayer="${16:-primary}"
    local Message=''
    local EligibilityStatus=0
    local Level=''
    local Index=0
    local Code=''
    local -a Rows=()

    [[ "$Context" == returning || "$Context" == shell ]] || return 80
    [[ "$TerminalLayer" == primary || "$TerminalLayer" == batch_parent ||
       "$TerminalLayer" == batch_child || "$TerminalLayer" == device_group ||
       "$TerminalLayer" == device_main ]] || return 80
    validate_journal_event "$Domain" "$Role" "$Detail" "$DeviceId" \
        "$MessageKey" "$ResultCode" "$Kind" "$Number" "$Boundary" || return $?
    validate_log_payload "$PayloadType" "$PayloadOne" "$PayloadTwo" \
        "$PayloadThree" "$PayloadFour" || return $?
    terminal_log_event_is_eligible "$Detail" "$Kind" "$ResultCode" || EligibilityStatus=$?
    (( EligibilityStatus == 0 || EligibilityStatus == 1 )) || return "$EligibilityStatus"
    if [[ "${LoggingState[UseFallback]:-false}" == true ]]; then
        Level="${DefaultValues[LogLevel]:-2}"
    else
        Level="${EffectiveConfig[LogLevel]:-}"
    fi
    interactive_tty_available || return 0
    render_log_message "$MessageKey" "$PayloadType" "$PayloadOne" \
        "$PayloadTwo" "$PayloadThree" "$PayloadFour" Message || return $?

    if [[ "$TerminalLayer" == device_group ]]; then
        [[ "$Role" == grouping && "$Kind" == ordinary ]] || return 80
        if [[ "${LoggingState[TerminalBatchActive]:-false}" == true ]]; then
            return 0
        fi
        (( EligibilityStatus == 0 )) || return 0
        Rows+=("$Message")
        terminal_log_replace_block Rows
        if [[ "$Context" == shell ]]; then
            LoggingState[TerminalRows]=0
        fi
        return 0
    fi

    if [[ "$TerminalLayer" == batch_parent ]]; then
        [[ "$Role" == main && ( "$Kind" == start || "$Kind" == outcome ) ]] || return 80
        if [[ "$Kind" == start ]]; then
            stop_terminal_log_spinner
            LoggingState[TerminalContext]="$Context"
            LoggingState[TerminalLevel]="$Level"
            LoggingState[TerminalMainActive]=false
            LoggingState[TerminalBatchActive]=true
            LoggingState[TerminalBatchParentVisible]=false
            (( EligibilityStatus == 0 )) && LoggingState[TerminalBatchParentVisible]=true
            LoggingState[TerminalBatchParentMessage]="$Message"
            LoggingState[TerminalBatchChildActive]=false
            LoggingState[TerminalBatchChildVisible]=false
            LoggingState[TerminalBatchChildMessage]=''
            LoggingState[TerminalDeviceMainActive]=false
            LoggingState[TerminalDeviceMainVisible]=false
            LoggingState[TerminalDeviceMainMessage]=''
            LoggingState[TerminalCurrentSubevent]=''
            TerminalLogBatchRows=()
            TerminalLogDeviceMainRows=()
            TerminalLogDeviceErrorMessages=()
            TerminalLogDeviceErrorCodes=()
            TerminalLogErrorMessages=()
            TerminalLogErrorCodes=()
            refresh_terminal_log_block true
            return 0
        fi
        [[ "${LoggingState[TerminalBatchActive]:-false}" == true ]] || return 80
        stop_terminal_log_spinner
        if [[ "$ResultCode" == 0 ]]; then
            if (( EligibilityStatus == 0 )); then
                Rows+=("${TerminalPalette[LoggingSuccess]}[OK]${TerminalPalette[Reset]} $Message")
            fi
        else
            Rows+=("${TerminalPalette[LoggingError]}[ER]${TerminalPalette[Reset]} $Message")
        fi
        Rows+=("${TerminalLogBatchRows[@]}")
        terminal_log_replace_block Rows
        if [[ "$Context" == shell ]]; then
            LoggingState[TerminalRows]=0
        fi
        LoggingState[TerminalBatchActive]=false
        LoggingState[TerminalBatchParentVisible]=false
        LoggingState[TerminalBatchParentMessage]=''
        LoggingState[TerminalBatchChildActive]=false
        LoggingState[TerminalBatchChildVisible]=false
        LoggingState[TerminalBatchChildMessage]=''
        LoggingState[TerminalDeviceMainActive]=false
        LoggingState[TerminalDeviceMainVisible]=false
        LoggingState[TerminalDeviceMainMessage]=''
        LoggingState[TerminalCurrentSubevent]=''
        TerminalLogBatchRows=()
        TerminalLogDeviceMainRows=()
        TerminalLogDeviceErrorMessages=()
        TerminalLogDeviceErrorCodes=()
        TerminalLogErrorMessages=()
        TerminalLogErrorCodes=()
        return 0
    fi

    if [[ "$TerminalLayer" == batch_child ]]; then
        [[ "${LoggingState[TerminalBatchActive]:-false}" == true ]] || return 80
        if [[ "$Role" == main && "$Kind" == start ]]; then
            stop_terminal_log_spinner
            LoggingState[TerminalContext]="$Context"
            LoggingState[TerminalBatchChildActive]=true
            LoggingState[TerminalBatchChildVisible]=false
            (( EligibilityStatus == 0 )) && LoggingState[TerminalBatchChildVisible]=true
            LoggingState[TerminalBatchChildMessage]="$Message"
            LoggingState[TerminalDeviceMainActive]=false
            LoggingState[TerminalDeviceMainVisible]=false
            LoggingState[TerminalDeviceMainMessage]=''
            LoggingState[TerminalCurrentSubevent]=''
            TerminalLogDeviceMainRows=()
            TerminalLogDeviceErrorMessages=()
            TerminalLogDeviceErrorCodes=()
            TerminalLogErrorMessages=()
            TerminalLogErrorCodes=()
            refresh_terminal_log_block true
            return 0
        fi
        if [[ "${LoggingState[TerminalBatchChildActive]:-false}" == true &&
              "$Kind" == error ]]; then
            TerminalLogErrorMessages+=("$Message")
            TerminalLogErrorCodes+=("$ResultCode")
            LoggingState[TerminalCurrentSubevent]=''
            refresh_terminal_log_block true
            return 0
        fi
        if [[ "${LoggingState[TerminalBatchChildActive]:-false}" == true &&
              "$Role" == subevent && "$Kind" == ordinary ]]; then
            if [[ "${LoggingState[TerminalLevel]:-}" == 3 && "$EligibilityStatus" == 0 ]]; then
                LoggingState[TerminalCurrentSubevent]="    [$Number] $Message"
                refresh_terminal_log_block true
            fi
            return 0
        fi
        [[ "$Role" == main && "$Kind" == outcome &&
           "${LoggingState[TerminalBatchChildActive]:-false}" == true ]] || return 80
        stop_terminal_log_spinner
        if (( ${#TerminalLogBatchRows[@]} > 0 )); then
            TerminalLogBatchRows+=('')
        fi
        if [[ "$ResultCode" == 0 ]]; then
            if (( EligibilityStatus == 0 )); then
                TerminalLogBatchRows+=("${TerminalPalette[LoggingSuccess]}[OK]${TerminalPalette[Reset]} $Message")
            fi
        else
            TerminalLogBatchRows+=("${TerminalPalette[LoggingError]}[ER]${TerminalPalette[Reset]} $Message")
            for ((Index=0; Index<${#TerminalLogErrorMessages[@]}; Index++)); do
                Code="${TerminalLogErrorCodes[Index]}"
                [[ -n "$Code" ]] || Code=ER
                TerminalLogBatchRows+=("${TerminalPalette[LoggingError]}[$Code]${TerminalPalette[Reset]} ${TerminalLogErrorMessages[Index]}")
            done
        fi
        LoggingState[TerminalBatchChildActive]=false
        LoggingState[TerminalBatchChildVisible]=false
        LoggingState[TerminalBatchChildMessage]=''
        LoggingState[TerminalDeviceMainActive]=false
        LoggingState[TerminalDeviceMainVisible]=false
        LoggingState[TerminalDeviceMainMessage]=''
        LoggingState[TerminalCurrentSubevent]=''
        TerminalLogDeviceMainRows=()
        TerminalLogDeviceErrorMessages=()
        TerminalLogDeviceErrorCodes=()
        TerminalLogErrorMessages=()
        TerminalLogErrorCodes=()
        refresh_terminal_log_block true
        return 0
    fi

    if [[ "$TerminalLayer" == device_main &&
          "${LoggingState[TerminalBatchActive]:-false}" == true ]]; then
        [[ "${LoggingState[TerminalBatchChildActive]:-false}" == true ]] || return 80
        if [[ "$Role" == main && "$Kind" == start ]]; then
            stop_terminal_log_spinner
            LoggingState[TerminalContext]="$Context"
            LoggingState[TerminalDeviceMainActive]=true
            LoggingState[TerminalDeviceMainVisible]=false
            (( EligibilityStatus == 0 )) && LoggingState[TerminalDeviceMainVisible]=true
            LoggingState[TerminalDeviceMainMessage]="$Message"
            LoggingState[TerminalCurrentSubevent]=''
            TerminalLogDeviceErrorMessages=()
            TerminalLogDeviceErrorCodes=()
            if [[ "$Boundary" == block && ${#TerminalLogDeviceMainRows[@]} -gt 0 ]]; then
                TerminalLogDeviceMainRows+=('')
            fi
            refresh_terminal_log_block true
            return 0
        fi
        [[ "${LoggingState[TerminalDeviceMainActive]:-false}" == true ]] || return 80
        if [[ "$Role" == subevent && "$Kind" == ordinary ]]; then
            if [[ "${LoggingState[TerminalLevel]:-}" == 3 && "$EligibilityStatus" == 0 ]]; then
                LoggingState[TerminalCurrentSubevent]="        [$Number] $Message"
                refresh_terminal_log_block true
            fi
            return 0
        fi
        if [[ "$Role" == subevent && "$Kind" == error ]]; then
            TerminalLogDeviceErrorMessages+=("$Message")
            TerminalLogDeviceErrorCodes+=("$ResultCode")
            LoggingState[TerminalCurrentSubevent]=''
            refresh_terminal_log_block true
            return 0
        fi
        [[ "$Role" == main && "$Kind" == outcome ]] || return 80
        stop_terminal_log_spinner
        if [[ "$ResultCode" == 0 ]]; then
            if (( EligibilityStatus == 0 )); then
                TerminalLogDeviceMainRows+=("    ${TerminalPalette[LoggingSuccess]}[OK]${TerminalPalette[Reset]} $Message")
            fi
        else
            TerminalLogDeviceMainRows+=("    ${TerminalPalette[LoggingError]}[ER]${TerminalPalette[Reset]} $Message")
            for ((Index=0; Index<${#TerminalLogDeviceErrorMessages[@]}; Index++)); do
                Code="${TerminalLogDeviceErrorCodes[Index]}"
                [[ -n "$Code" ]] || Code=ER
                TerminalLogDeviceMainRows+=("        ${TerminalPalette[LoggingError]}[$Code]${TerminalPalette[Reset]} ${TerminalLogDeviceErrorMessages[Index]}")
            done
        fi
        LoggingState[TerminalDeviceMainActive]=false
        LoggingState[TerminalDeviceMainVisible]=false
        LoggingState[TerminalDeviceMainMessage]=''
        LoggingState[TerminalCurrentSubevent]=''
        TerminalLogDeviceErrorMessages=()
        TerminalLogDeviceErrorCodes=()
        refresh_terminal_log_block true
        return 0
    fi

    if [[ "${LoggingState[TerminalBatchActive]:-false}" == true && "$Kind" == error ]]; then
        if [[ "${LoggingState[TerminalBatchChildActive]:-false}" == true ]]; then
            TerminalLogErrorMessages+=("$Message")
            TerminalLogErrorCodes+=("$ResultCode")
        else
            if (( ${#TerminalLogBatchRows[@]} > 0 )); then
                TerminalLogBatchRows+=('')
            fi
            Code="$ResultCode"
            [[ -n "$Code" ]] || Code=ER
            TerminalLogBatchRows+=("${TerminalPalette[LoggingError]}[$Code]${TerminalPalette[Reset]} $Message")
        fi
        refresh_terminal_log_block true
        return 0
    fi

    if [[ "$Role" == main && "$Kind" == start ]]; then
        stop_terminal_log_spinner
        LoggingState[TerminalContext]="$Context"
        LoggingState[TerminalLevel]="$Level"
        LoggingState[TerminalMainActive]=true
        LoggingState[TerminalMainMessage]="$Message"
        LoggingState[TerminalMainVisible]=false
        (( EligibilityStatus == 0 )) && LoggingState[TerminalMainVisible]=true
        LoggingState[TerminalCurrentSubevent]=''
        TerminalLogErrorMessages=()
        TerminalLogErrorCodes=()
        refresh_terminal_log_block true
        return 0
    fi

    if [[ "${LoggingState[TerminalMainActive]:-false}" == true &&
          "$Kind" == error ]]; then
        TerminalLogErrorMessages+=("$Message")
        TerminalLogErrorCodes+=("$ResultCode")
        LoggingState[TerminalCurrentSubevent]=''
        refresh_terminal_log_block true
        return 0
    fi

    if [[ "${LoggingState[TerminalMainActive]:-false}" == true &&
          "$Role" == subevent && "$Kind" == ordinary ]]; then
        if [[ "${LoggingState[TerminalLevel]:-}" == 3 && "$EligibilityStatus" == 0 ]]; then
            LoggingState[TerminalCurrentSubevent]="    [$Number] $Message"
            refresh_terminal_log_block true
        fi
        return 0
    fi

    if [[ "$Role" == main && "$Kind" == outcome ]]; then
        stop_terminal_log_spinner
        LoggingState[TerminalMainActive]=false
        LoggingState[TerminalMainMessage]="$Message"
        LoggingState[TerminalCurrentSubevent]=''
        if [[ "$ResultCode" == 0 ]]; then
            if (( EligibilityStatus == 0 )); then
                Rows+=("${TerminalPalette[LoggingSuccess]}[OK]${TerminalPalette[Reset]} $Message")
            fi
        else
            Rows+=("${TerminalPalette[LoggingError]}[ER]${TerminalPalette[Reset]} $Message")
            for ((Index=0; Index<${#TerminalLogErrorMessages[@]}; Index++)); do
                Code="${TerminalLogErrorCodes[Index]}"
                [[ -n "$Code" ]] || Code=ER
                Rows+=("${TerminalPalette[LoggingError]}[$Code]${TerminalPalette[Reset]} ${TerminalLogErrorMessages[Index]}")
            done
        fi
        terminal_log_replace_block Rows
        if [[ "$Context" == shell ]]; then
            LoggingState[TerminalRows]=0
        fi
        TerminalLogErrorMessages=()
        TerminalLogErrorCodes=()
        return 0
    fi

    (( EligibilityStatus == 0 )) || return 0
    if [[ "$Kind" == error ]]; then
        Code="$ResultCode"
        [[ -n "$Code" ]] || Code=ER
        Rows+=("${TerminalPalette[LoggingError]}[$Code]${TerminalPalette[Reset]} $Message")
    else
        Rows+=("$Message")
    fi
    terminal_log_replace_block Rows
    if [[ "$Context" == shell ]]; then
        LoggingState[TerminalRows]=0
    fi
    return 0
}

# Назначение: Проверяет tty, сохраняет его состояние и выполняет переданный UI callback с гарантированным восстановлением.
run_terminal_ui()
{
    local Status=0

    interactive_tty_available || return 31
    capture_terminal_state || return 31
    RuntimeState[TerminalFrameValidation]=true
    "$@" || Status=$?
    restore_terminal_state || Status=31
    RuntimeState[TerminalFrameValidation]=false
    if (( Status == 31 )) && [[ -n "${RuntimeState[GeometryRequiredWidth]:-}" ]]; then
        emit_terminal_geometry_diagnostic
    fi
    return "$Status"
}

# Назначение: Читает один навигационный key sequence с tty и нормализует escape-последовательности клавиш.
# shellcheck disable=SC2034  # KeyOut is a nameref output.
ui_read_key()
{
    local -n KeyOut="$1"
    local First=''
    local Second=''
    local Character=''
    local Sequence=''

    KeyOut=unknown
    IFS= read -r -n 1 First <&0 || return 1
    if [[ "$First" == $'\033' ]]; then
        IFS= read -r -n 1 -t 0.05 Second <&0 || Second=''
        Sequence="$Second"
        if [[ "$Second" == '[' ]]; then
            while (( ${#Sequence} < 8 )); do
                IFS= read -r -n 1 -t 0.05 Character <&0 || break
                Sequence+="$Character"
                [[ "$Character" == [[:alpha:]~] ]] && break
            done
        fi
        case "$Sequence" in
            '[A') KeyOut=up ;;
            '[B') KeyOut=down ;;
            '[5~') KeyOut=page_up ;;
            '[6~') KeyOut=page_down ;;
            *) KeyOut=unknown ;;
        esac
    elif [[ -z "$First" || "$First" == $'\n' || "$First" == $'\r' ]]; then
        KeyOut=enter
    elif [[ "$First" == [0-9] ]]; then
        KeyOut="digit:$First"
    fi
    return 0
}

# Назначение: Вычисляет допустимую ширину/высоту frame с учётом terminal geometry и минимальных размеров.
ui_frame_dimensions()
{
    local Frame="$1"
    local -n WidthOut="$2"
    local -n HeightOut="$3"
    local Plain=''
    local Line=''

    ui_strip_ansi "$Frame" Plain
    WidthOut=0
    HeightOut=0
    while IFS= read -r Line || [[ -n "$Line" ]]; do
        ((HeightOut++))
        (( ${#Line} > WidthOut )) && WidthOut="${#Line}"
    done <<< "$Plain"
    [[ "$Plain" == *$'\n' ]] && ((HeightOut--))
    return 0
}

# Назначение: Получает rows/columns через stty и отвергает неполные либо нечисловые результаты.
# shellcheck disable=SC2034  # Geometry values are returned through namerefs.
ui_read_terminal_geometry()
{
    local -n RowsOut="$1"
    local -n ColumnsOut="$2"
    local Geometry=''

    Geometry="$(stty size <&0 2>/dev/null)" || Geometry='0 0'
    RowsOut="${Geometry%% *}"
    ColumnsOut="${Geometry##* }"
    if [[ ! "$RowsOut" =~ ^[0-9]+$ || ! "$ColumnsOut" =~ ^[0-9]+$ ]]; then
        RowsOut=0
        ColumnsOut=0
    fi
    return 0
}

# Назначение: Публикует готовый массив строк одним cursor-controlled обновлением экрана.
ui_publish_frame()
{
    local Frame="$1"
    local ActualRows="${2:-}"
    local ActualColumns="${3:-}"
    local RequiredWidth=0
    local RequiredHeight=0

    ui_frame_dimensions "$Frame" RequiredWidth RequiredHeight || return $?
    if [[ "${RuntimeState[TerminalFrameValidation]:-false}" == true ]]; then
        if [[ -z "$ActualRows" || -z "$ActualColumns" ]]; then
            ui_read_terminal_geometry ActualRows ActualColumns || return $?
        fi
        if (( ActualColumns < RequiredWidth || ActualRows < RequiredHeight )); then
            RuntimeState[GeometryActualWidth]="$ActualColumns"
            RuntimeState[GeometryActualHeight]="$ActualRows"
            RuntimeState[GeometryRequiredWidth]="$RequiredWidth"
            RuntimeState[GeometryRequiredHeight]="$RequiredHeight"
            return 31
        fi
    fi
    printf '%s' "$Frame"
    return 0
}

# Назначение: Выводит понятную ошибку, когда терминал слишком мал для требуемого UI.
emit_terminal_geometry_diagnostic()
{
    local Diagnostic=''

    localized_message terminal_geometry_error Diagnostic
    printf '%s %sx%s / %sx%s.\n' "$Diagnostic" \
        "${RuntimeState[GeometryActualWidth]:-0}" "${RuntimeState[GeometryActualHeight]:-0}" \
        "${RuntimeState[GeometryRequiredWidth]:-0}" "${RuntimeState[GeometryRequiredHeight]:-0}" >&2
    unset 'RuntimeState[GeometryActualWidth]' 'RuntimeState[GeometryActualHeight]' \
        'RuntimeState[GeometryRequiredWidth]' 'RuntimeState[GeometryRequiredHeight]'
    return 0
}

# Назначение: Переносит ANSI-свободный текст по display width, сохраняя слова и явно заданные пустые строки.
# shellcheck disable=SC2034  # WrappedLinesOut is a nameref output.
ui_wrap_text()
{
    local Text="$1"
    local Width="$2"
    local -n WrappedLinesOut="$3"
    local Word=''
    local Line=''
    local Chunk=''
    local -a Words=()

    (( Width > 0 )) || return 80
    ui_strip_ansi "$Text" Text
    Text="${Text//$'\n'/ }"
    read -r -a Words <<< "$Text"
    WrappedLinesOut=()
    for Word in "${Words[@]}"; do
        while (( ${#Word} > Width )); do
            if [[ -n "$Line" ]]; then
                WrappedLinesOut+=("$Line")
                Line=''
            fi
            Chunk="${Word:0:Width}"
            WrappedLinesOut+=("$Chunk")
            Word="${Word:Width}"
        done
        [[ -n "$Word" ]] || continue
        if [[ -z "$Line" ]]; then
            Line="$Word"
        elif (( ${#Line} + 1 + ${#Word} <= Width )); then
            Line+=" $Word"
        else
            WrappedLinesOut+=("$Line")
            Line="$Word"
        fi
    done
    if [[ -n "$Line" || ${#WrappedLinesOut[@]} -eq 0 ]]; then
        WrappedLinesOut+=("$Line")
    fi
    return 0
}

# Назначение: Выбирает цветовую роль значения Editor по типу поля и его текущему содержимому.
ui_editor_value_palette_role()
{
    local Kind="$1"
    local RawValue="$2"

    case "$Kind:$RawValue" in
        boolean:true) printf '%s' EditorValueYes ;;
        boolean:false) printf '%s' EditorValueNo ;;
        path:*) printf '%s' EditorValuePath ;;
        *) printf '%s' EditorValueOrdinary ;;
    esac
    return 0
}

# Назначение: Строит кадр меню с выбранной строкой, описанием и недоступными действиями.
ui_render_menu_selection()
{
    local Title="$1"
    local ItemsName="$2"
    local Selected="$3"
    local DisabledName="$4"
    local DescriptionsName="$5"
    local SeparatorBefore="$6"
    local -n MenuItems="$ItemsName"
    local -n MenuDisabled="$DisabledName"
    local -n MenuDescriptions="$DescriptionsName"
    local Header=''
    local Frame=''
    local Border=''
    local Separator=''
    local Padding=''
    local Row=''
    local Index=0
    local HintHeight=1
    local -a HintLines=()
    local -a CandidateLines=()

    for Row in "${MenuDescriptions[@]}"; do
        ui_wrap_text "$Row" "$((UiWidth - 4))" CandidateLines || return $?
        (( ${#CandidateLines[@]} > HintHeight )) && HintHeight="${#CandidateLines[@]}"
    done
    ui_wrap_text "${MenuDescriptions[Selected]:-}" "$((UiWidth - 4))" HintLines || return $?
    while (( ${#HintLines[@]} < HintHeight )); do HintLines+=(''); done
    build_product_header "$UiWidth" Header || return $?
    printf -v Border '%*s' "$UiWidth" ''
    Border="${Border// /-}"
    printf -v Separator '%*s' "$((UiWidth - 2))" ''
    Separator="  ${Separator// /=}"
    printf -v Frame '\033[2J\033[H%s%s%s\n\n%s%s%s\n' \
        "${TerminalPalette[ProductHeader]}" "$Header" "${TerminalPalette[Reset]}" \
        "${TerminalPalette[MainTitle]}" "$Title" "${TerminalPalette[Reset]}"
    Frame+="${TerminalPalette[MainDescription]}${Border}${TerminalPalette[Reset]}"$'\n'
    for Row in "${HintLines[@]}"; do
        printf -v Padding '%*s' "$((UiWidth - 4 - ${#Row}))" ''
        Frame+="${TerminalPalette[MainDescription]}| ${Row}${Padding} |${TerminalPalette[Reset]}"$'\n'
    done
    Frame+="${TerminalPalette[MainDescription]}${Border}${TerminalPalette[Reset]}"$'\n\n'
    for ((Index=0; Index<${#MenuItems[@]}; Index++)); do
        (( Index == SeparatorBefore )) && Frame+="${TerminalPalette[EditorStructural]}${Separator}${TerminalPalette[Reset]}"$'\n'
        if [[ "${MenuDisabled[Index]:-false}" == true ]]; then
            Frame+="${TerminalPalette[EditorDisabled]}  ${MenuItems[Index]}${TerminalPalette[Reset]}"$'\n'
        elif (( Index == Selected )); then
            Frame+="${TerminalPalette[EditorSelected]}> ${MenuItems[Index]}${TerminalPalette[Reset]}"$'\n'
        else
            Frame+="${TerminalPalette[EditorLabel]}  ${MenuItems[Index]}${TerminalPalette[Reset]}"$'\n'
        fi
    done
    ui_publish_frame "$Frame"
}

# Назначение: Преобразует структурированные роли/строки документа в плоские render rows с переносами.
# shellcheck disable=SC2034  # Flattened document vectors are returned through namerefs.
ui_flatten_document_source()
{
    local RolesName="$1"
    local LinesName="$2"
    local Width="$3"
    local -n FlatRolesOut="$4"
    local -n FlatLinesOut="$5"
    local -n LogicalRoles="$RolesName"
    local -n LogicalLines="$LinesName"
    local Index=0
    local Role=''
    local Row=''
    local -a Wrapped=()

    FlatRolesOut=()
    FlatLinesOut=()
    for ((Index=0; Index<${#LogicalLines[@]}; Index++)); do
        Role="${LogicalRoles[Index]}"
        if [[ "$Role" == blank ]]; then
            FlatRolesOut+=(blank)
            FlatLinesOut+=('')
            continue
        fi
        case "$Role" in
            heading|text|code) : ;;
            *) return 80 ;;
        esac
        ui_wrap_text "${LogicalLines[Index]}" "$((Width - 4))" Wrapped || return $?
        for Row in "${Wrapped[@]}"; do
            FlatRolesOut+=("$Role")
            FlatLinesOut+=("$Row")
        done
    done
    return 0
}

# Назначение: Вычисляет окно прокрутки и формирует полный кадр Help/Instruction для текущей позиции.
# shellcheck disable=SC2034  # FrameOut is a nameref output.
ui_build_document_frame()
{
    local Title="$1"
    local ItemsName="$2"
    local Selected="$3"
    local RolesName="$4"
    local LinesName="$5"
    local Width="$6"
    local HintsName="$7"
    local TitleRole="$8"
    local LowerSeparator="$9"
    local PageStatus="${10}"
    local -n FrameOut="${11}"
    local -n DocumentItems="$ItemsName"
    local -n DocumentRoles="$RolesName"
    local -n DocumentLines="$LinesName"
    local Header=''
    local HintBorder=''
    local DocumentBorder=''
    local Separator=''
    local Padding=''
    local Role=''
    local PaletteRole=DocumentText
    local Row=''
    local Index=0
    local HintHeight=1
    local -a HintLines=()
    local -a CandidateLines=()

    build_product_header "$Width" Header || return $?
    printf -v HintBorder '%*s' "$Width" ''
    HintBorder="${HintBorder// /-}"
    printf -v DocumentBorder '%*s' "$((Width - 2))" ''
    DocumentBorder="+${DocumentBorder// /-}+"
    printf -v Separator '%*s' "$((Width - 2))" ''
    Separator="  ${Separator// /=}"
    printf -v FrameOut '\033[2J\033[H%s%s%s\n\n%s%s%s\n' \
        "${TerminalPalette[ProductHeader]}" "$Header" "${TerminalPalette[Reset]}" \
        "${TerminalPalette[$TitleRole]}" "$Title" "${TerminalPalette[Reset]}"
    if [[ -n "$HintsName" ]]; then
        local -n DocumentHints="$HintsName"
        for Row in "${DocumentHints[@]}"; do
            ui_wrap_text "$Row" "$((Width - 4))" CandidateLines || return $?
            (( ${#CandidateLines[@]} > HintHeight )) && HintHeight="${#CandidateLines[@]}"
        done
        ui_wrap_text "${DocumentHints[Selected]:-}" "$((Width - 4))" HintLines || return $?
        while (( ${#HintLines[@]} < HintHeight )); do HintLines+=(''); done
        FrameOut+="${TerminalPalette[HelpDescription]}${HintBorder}${TerminalPalette[Reset]}"$'\n'
        for Row in "${HintLines[@]}"; do
            printf -v Padding '%*s' "$((Width - 4 - ${#Row}))" ''
            FrameOut+="${TerminalPalette[HelpDescription]}| ${Row}${Padding} |${TerminalPalette[Reset]}"$'\n'
        done
        FrameOut+="${TerminalPalette[HelpDescription]}${HintBorder}${TerminalPalette[Reset]}"$'\n'
    fi
    FrameOut+=$'\n'
    FrameOut+="${TerminalPalette[EditorStructural]}${DocumentBorder}${TerminalPalette[Reset]}"$'\n'
    for ((Index=0; Index<${#DocumentLines[@]}; Index++)); do
        Role="${DocumentRoles[Index]}"
        if [[ "$Role" == blank ]]; then
            FrameOut+="${TerminalPalette[EditorStructural]}|$(printf '%*s' "$((Width - 2))" '')|${TerminalPalette[Reset]}"$'\n'
            continue
        fi
        case "$Role" in
            heading) PaletteRole=DocumentHeading ;;
            code) PaletteRole=DocumentCode ;;
            *) PaletteRole=DocumentText ;;
        esac
        Row="${DocumentLines[Index]}"
        printf -v Padding '%*s' "$((Width - 4 - ${#Row}))" ''
        FrameOut+="${TerminalPalette[EditorStructural]}| ${TerminalPalette[$PaletteRole]}${Row}${Padding}${TerminalPalette[Reset]} ${TerminalPalette[EditorStructural]}|${TerminalPalette[Reset]}"$'\n'
    done
    FrameOut+="${TerminalPalette[EditorStructural]}${DocumentBorder}${TerminalPalette[Reset]}"$'\n'
    if [[ -n "$PageStatus" ]]; then
        FrameOut+="${TerminalPalette[EditorStructural]}${PageStatus}${TerminalPalette[Reset]}"$'\n'
    fi
    [[ "$LowerSeparator" == true ]] && FrameOut+="${TerminalPalette[EditorStructural]}${Separator}${TerminalPalette[Reset]}"$'\n'
    for ((Index=0; Index<${#DocumentItems[@]}; Index++)); do
        if (( Index == Selected )); then
            FrameOut+="${TerminalPalette[EditorSelected]}> ${DocumentItems[Index]}${TerminalPalette[Reset]}"$'\n'
        else
            FrameOut+="${TerminalPalette[EditorLabel]}  ${DocumentItems[Index]}${TerminalPalette[Reset]}"$'\n'
        fi
    done
    return 0
}

# Назначение: Управляет просмотром прокручиваемого документа до Return/Exit, не меняя его источник.
# shellcheck disable=SC2034,SC2154  # Pager keys are selected dynamically through a nameref.
ui_render_document_selection()
{
    local Title="$1"
    local ItemsName="$2"
    local Selected="$3"
    local RolesName="$4"
    local LinesName="$5"
    local Width="$6"
    local HintsName="$7"
    local TitleRole="$8"
    local LowerSeparator="$9"
    local PagerName="${10:-}"
    local -A LocalPager=([Current]=0 [Count]=1 [Capacity]=0)
    local NaturalFrame=''
    local PageFrame=''
    local PageLabel=''
    local ScrollLabel=''
    local PageStatus=''
    local ActualRows=0
    local ActualColumns=0
    local NaturalWidth=0
    local NaturalHeight=0
    local FixedRows=0
    local PageCapacity=0
    local PageCount=1
    local CurrentPage=0
    local Start=0
    local End=0
    local Index=0
    local TotalLines=0
    local -a PhysicalRoles=()
    local -a PhysicalLines=()
    local -a PageRoles=()
    local -a PageLines=()

    [[ -n "$PagerName" ]] || PagerName=LocalPager
    local -n PagerState="$PagerName"
    ui_flatten_document_source "$RolesName" "$LinesName" "$Width" PhysicalRoles PhysicalLines || return $?
    TotalLines="${#PhysicalLines[@]}"
    (( TotalLines > 0 )) || return 80
    ui_build_document_frame "$Title" "$ItemsName" "$Selected" \
        PhysicalRoles PhysicalLines "$Width" "$HintsName" "$TitleRole" \
        "$LowerSeparator" '' NaturalFrame || return $?
    ui_frame_dimensions "$NaturalFrame" NaturalWidth NaturalHeight || return $?
    (( NaturalWidth == Width )) || return 80

    if [[ "${RuntimeState[TerminalFrameValidation]:-false}" != true ]]; then
        PagerState[Current]=0
        PagerState[Count]=1
        PagerState[Capacity]="$TotalLines"
        ui_publish_frame "$NaturalFrame"
        return $?
    fi

    ui_read_terminal_geometry ActualRows ActualColumns || return $?
    if (( ActualColumns < Width )); then
        RuntimeState[GeometryActualWidth]="$ActualColumns"
        RuntimeState[GeometryActualHeight]="$ActualRows"
        RuntimeState[GeometryRequiredWidth]="$Width"
        RuntimeState[GeometryRequiredHeight]="$NaturalHeight"
        return 31
    fi
    if (( ActualRows >= NaturalHeight )); then
        PagerState[Current]=0
        PagerState[Count]=1
        PagerState[Capacity]="$TotalLines"
        ui_publish_frame "$NaturalFrame" "$ActualRows" "$ActualColumns"
        return $?
    fi

    FixedRows=$((NaturalHeight - TotalLines + 1))
    PageCapacity=$((ActualRows - FixedRows))
    if (( PageCapacity < 1 )); then
        RuntimeState[GeometryActualWidth]="$ActualColumns"
        RuntimeState[GeometryActualHeight]="$ActualRows"
        RuntimeState[GeometryRequiredWidth]="$Width"
        RuntimeState[GeometryRequiredHeight]="$((FixedRows + 1))"
        return 31
    fi
    PageCount=$(((TotalLines + PageCapacity - 1) / PageCapacity))
    CurrentPage="${PagerState[Current]:-0}"
    [[ "$CurrentPage" =~ ^[0-9]+$ ]] || CurrentPage=0
    (( CurrentPage < PageCount )) || CurrentPage=$((PageCount - 1))
    PagerState[Current]="$CurrentPage"
    PagerState[Count]="$PageCount"
    PagerState[Capacity]="$PageCapacity"

    Start=$((CurrentPage * PageCapacity))
    End=$((Start + PageCapacity))
    (( End <= TotalLines )) || End="$TotalLines"
    for ((Index=Start; Index<End; Index++)); do
        PageRoles+=("${PhysicalRoles[Index]}")
        PageLines+=("${PhysicalLines[Index]}")
    done
    while (( ${#PageLines[@]} < PageCapacity )); do
        PageRoles+=(blank)
        PageLines+=('')
    done
    localized_message page_label PageLabel
    localized_message page_scroll ScrollLabel
    printf -v PageStatus '%s %d/%d    PageUp/PageDown - %s' \
        "$PageLabel" "$((CurrentPage + 1))" "$PageCount" "$ScrollLabel"
    ui_build_document_frame "$Title" "$ItemsName" "$Selected" \
        PageRoles PageLines "$Width" "$HintsName" "$TitleRole" \
        "$LowerSeparator" "$PageStatus" PageFrame || return $?
    ui_publish_frame "$PageFrame" "$ActualRows" "$ActualColumns"
}

# Назначение: Рисует форму Editor/Master в прокручиваемом viewport, сохраняя выбранную логическую строку видимой.
ui_render_form_selection()
{
    local Title="$1"
    local ItemsName="$2"
    local Selected="$3"
    local DisabledName="$4"
    local LabelsName="$5"
    local ValuesName="$6"
    local KindsName="$7"
    local RawValuesName="$8"
    local DescriptionsName="$9"
    local FieldCount="${10}"
    local TitleRole="${11:-EditorTitle}"
    local DescriptionRole="${12:-EditorDescription}"
    local ViewportName="${13:-}"
    local -A LocalViewport=([Start]=0 [End]=0 [Capacity]=0)
    : "${LocalViewport[Start]}"
    [[ -n "$ViewportName" ]] || ViewportName=LocalViewport
    local -n ViewportState="$ViewportName"
    local -n EditorRenderItems="$ItemsName"
    local -n EditorRenderDisabled="$DisabledName"
    local -n EditorRenderLabels="$LabelsName"
    local -n EditorRenderValues="$ValuesName"
    local -n EditorRenderKinds="$KindsName"
    local -n EditorRenderRawValues="$RawValuesName"
    local -n EditorRenderDescriptions="$DescriptionsName"
    local Index=0
    local Frame=''
    local Row=''
    local Header=''
    local UsableWidth=$((UiWidth - 4))
    local Border=''
    local Separator=''
    local SeparatorBody=''
    local Padding=''
    local ValueRole=''
    local Description="${EditorRenderDescriptions[Selected]:-}"
    local NaturalFrame=''
    local NaturalWidth=0
    local NaturalHeight=0
    local ActualRows=0
    local ActualColumns=0
    local FixedRows=0
    local AvailableRows=0
    local TotalItems="${#EditorRenderItems[@]}"
    local Start=0
    local End=0
    local UsedRows=0
    local AddedRows=0
    local CandidateStart=0
    local CandidateRows=0
    local -a DescriptionLines=()
    local -a CandidateLines=()
    local CandidateDescription=''
    local DescriptionHeight=1

    for CandidateDescription in "${EditorRenderDescriptions[@]}"; do
        ui_wrap_text "$CandidateDescription" "$UsableWidth" CandidateLines || return $?
        (( ${#CandidateLines[@]} > DescriptionHeight )) && DescriptionHeight="${#CandidateLines[@]}"
    done
    ui_wrap_text "$Description" "$UsableWidth" DescriptionLines || return $?
    while (( ${#DescriptionLines[@]} < DescriptionHeight )); do DescriptionLines+=(''); done
    build_product_header "$UiWidth" Header || return $?
    printf -v Border '%*s' "$UiWidth" ''
    Border="${Border// /-}"
    printf -v SeparatorBody '%*s' "$((UiWidth - 2))" ''
    Separator="  ${SeparatorBody// /=}"

    printf -v Frame '\033[2J\033[H%s%s%s\n\n%s%s%s\n' \
        "${TerminalPalette[ProductHeader]}" "$Header" "${TerminalPalette[Reset]}" \
        "${TerminalPalette[$TitleRole]}" "$Title" "${TerminalPalette[Reset]}"
    Frame+="${TerminalPalette[$DescriptionRole]}${Border}${TerminalPalette[Reset]}"$'\n'
    for Row in "${DescriptionLines[@]}"; do
        printf -v Padding '%*s' "$((UsableWidth - ${#Row}))" ''
        Frame+="${TerminalPalette[$DescriptionRole]}| ${Row}${Padding} |${TerminalPalette[Reset]}"$'\n'
    done
    Frame+="${TerminalPalette[$DescriptionRole]}${Border}${TerminalPalette[Reset]}"$'\n\n'

    NaturalFrame="$Frame"
    for ((Index=0; Index<TotalItems; Index++)); do
        if (( Index == FieldCount )); then
            NaturalFrame+="${TerminalPalette[EditorStructural]}${Separator}${TerminalPalette[Reset]}"$'\n'
        fi
        if [[ "${EditorRenderDisabled[Index]:-false}" == true ]]; then
            NaturalFrame+="${TerminalPalette[EditorDisabled]}  ${EditorRenderItems[Index]}${TerminalPalette[Reset]}"$'\n'
        elif (( Index == Selected )); then
            NaturalFrame+="${TerminalPalette[EditorSelected]}> ${EditorRenderItems[Index]}${TerminalPalette[Reset]}"$'\n'
        elif (( Index < FieldCount )); then
            ValueRole="$(ui_editor_value_palette_role \
                "${EditorRenderKinds[Index]}" "${EditorRenderRawValues[Index]}")"
            NaturalFrame+="  ${TerminalPalette[EditorLabel]}${EditorRenderLabels[Index]}=${TerminalPalette[Reset]}"
            NaturalFrame+="${TerminalPalette[$ValueRole]}${EditorRenderValues[Index]}${TerminalPalette[Reset]}"$'\n'
        else
            NaturalFrame+="  ${TerminalPalette[EditorLabel]}${EditorRenderItems[Index]}${TerminalPalette[Reset]}"$'\n'
        fi
    done
    ui_frame_dimensions "$NaturalFrame" NaturalWidth NaturalHeight || return $?
    if [[ "${RuntimeState[TerminalFrameValidation]:-false}" != true ]]; then
        ViewportState[Start]=0
        ViewportState[End]="$TotalItems"
        ViewportState[Capacity]="$TotalItems"
        ui_publish_frame "$NaturalFrame"
        return $?
    fi

    ui_read_terminal_geometry ActualRows ActualColumns || return $?
    if (( ActualColumns < NaturalWidth )); then
        RuntimeState[GeometryActualWidth]="$ActualColumns"
        RuntimeState[GeometryActualHeight]="$ActualRows"
        RuntimeState[GeometryRequiredWidth]="$NaturalWidth"
        RuntimeState[GeometryRequiredHeight]="$NaturalHeight"
        return 31
    fi
    if (( ActualRows >= NaturalHeight )); then
        ViewportState[Start]=0
        ViewportState[End]="$TotalItems"
        ViewportState[Capacity]="$TotalItems"
        ui_publish_frame "$NaturalFrame" "$ActualRows" "$ActualColumns"
        return $?
    fi

    FixedRows=$((NaturalHeight - TotalItems))
    (( FieldCount < TotalItems )) && ((FixedRows--))
    AvailableRows=$((ActualRows - FixedRows))
    if (( AvailableRows < 1 )); then
        RuntimeState[GeometryActualWidth]="$ActualColumns"
        RuntimeState[GeometryActualHeight]="$ActualRows"
        RuntimeState[GeometryRequiredWidth]="$NaturalWidth"
        RuntimeState[GeometryRequiredHeight]="$((FixedRows + 1))"
        return 31
    fi

    Start="${ViewportState[Start]:-0}"
    [[ "$Start" =~ ^[0-9]+$ ]] || Start=0
    (( Start < TotalItems )) || Start=$((TotalItems - 1))
    (( Selected < Start )) && Start="$Selected"
    while (( Start < Selected )); do
        UsedRows=$((Selected - Start + 1))
        if (( Start < FieldCount && Selected >= FieldCount )); then
            ((UsedRows++))
        fi
        (( UsedRows <= AvailableRows )) && break
        ((Start++))
    done

    End="$Start"
    UsedRows=0
    while (( End < TotalItems )); do
        AddedRows=1
        if (( End == FieldCount && Start < FieldCount )); then
            ((AddedRows++))
        fi
        (( UsedRows + AddedRows <= AvailableRows )) || break
        UsedRows=$((UsedRows + AddedRows))
        ((End++))
    done
    if (( Selected >= End )); then
        Start="$Selected"
        End=$((Selected + 1))
        UsedRows=1
    fi

    if (( End == TotalItems )); then
        while (( Start > 0 )); do
            CandidateStart=$((Start - 1))
            CandidateRows=$((TotalItems - CandidateStart))
            if (( CandidateStart < FieldCount && TotalItems > FieldCount )); then
                ((CandidateRows++))
            fi
            (( CandidateRows <= AvailableRows )) || break
            Start="$CandidateStart"
        done
        End="$Start"
        UsedRows=0
        while (( End < TotalItems )); do
            AddedRows=1
            if (( End == FieldCount && Start < FieldCount )); then
                ((AddedRows++))
            fi
            (( UsedRows + AddedRows <= AvailableRows )) || break
            UsedRows=$((UsedRows + AddedRows))
            ((End++))
        done
    fi

    ViewportState[Start]="$Start"
    ViewportState[End]="$End"
    ViewportState[Capacity]="$AvailableRows"
    for ((Index=Start; Index<End; Index++)); do
        if (( Index == FieldCount && Start < FieldCount )); then
            Frame+="${TerminalPalette[EditorStructural]}${Separator}${TerminalPalette[Reset]}"$'\n'
        fi
        if [[ "${EditorRenderDisabled[Index]:-false}" == true ]]; then
            Frame+="${TerminalPalette[EditorDisabled]}  ${EditorRenderItems[Index]}${TerminalPalette[Reset]}"$'\n'
        elif (( Index == Selected )); then
            Frame+="${TerminalPalette[EditorSelected]}> ${EditorRenderItems[Index]}${TerminalPalette[Reset]}"$'\n'
        elif (( Index < FieldCount )); then
            ValueRole="$(ui_editor_value_palette_role \
                "${EditorRenderKinds[Index]}" "${EditorRenderRawValues[Index]}")"
            Frame+="  ${TerminalPalette[EditorLabel]}${EditorRenderLabels[Index]}=${TerminalPalette[Reset]}"
            Frame+="${TerminalPalette[$ValueRole]}${EditorRenderValues[Index]}${TerminalPalette[Reset]}"$'\n'
        else
            Frame+="  ${TerminalPalette[EditorLabel]}${EditorRenderItems[Index]}${TerminalPalette[Reset]}"$'\n'
        fi
    done
    ui_publish_frame "$Frame" "$ActualRows" "$ActualColumns"
}

# Назначение: Назначает палитру строке универсального selector по structural/disabled/selected состоянию.
ui_generic_row_palette_role()
{
    local Kind="${1:-ordinary}"
    local RawValue="${2:-}"

    case "$Kind:$RawValue" in
        boolean:true) printf '%s' EditorValueYes ;;
        boolean:false) printf '%s' EditorValueNo ;;
        structural:*) printf '%s' EditorStructural ;;
        *) printf '%s' EditorLabel ;;
    esac
    return 0
}

# Назначение: Запускает общий цикл навигации, вызывает renderer и возвращает подтверждённый индекс или отмену.
ui_render_selection()
{
    local Title="$1"
    local ItemsName="$2"
    local Selected="$3"
    local SummaryConfigName="${4:-}"
    local DisabledName="${5:-}"
    local PresentationProfile="${6:-}"
    local -n RenderItems="$ItemsName"
    local Index=0
    local Frame=''
    local Row=''
    local SummaryText=''
    local SummaryLine=''
    local -a SummaryWrapped=()
    local Header=''
    local TitleRole=EditorTitle
    local KindsName="${7:-}"
    local RawValuesName="${8:-}"
    local Kind=ordinary
    local RawValue=''
    local RowRole=EditorLabel

    if [[ "$PresentationProfile" == editor ]]; then
        ui_render_form_selection "$Title" "$ItemsName" "$Selected" "$DisabledName" \
            "${7}" "${8}" "${9}" "${10}" "${11}" "${12}" EditorTitle EditorDescription "${15:-}"
        return $?
    fi
    if [[ "$PresentationProfile" == master_form ]]; then
        ui_render_form_selection "$Title" "$ItemsName" "$Selected" "$DisabledName" \
            "${7}" "${8}" "${9}" "${10}" "${11}" "${12}" \
            MasterTitle MasterDescription "${15:-}"
        return $?
    fi
    if [[ "$PresentationProfile" == main ]]; then
        ui_render_menu_selection "$Title" "$ItemsName" "$Selected" "$DisabledName" "${7}" "${8}"
        return $?
    fi
    if [[ "$PresentationProfile" == document ]]; then
        ui_render_document_selection "$Title" "$ItemsName" "$Selected" \
            "${7}" "${8}" "${9}" "${10}" "${11}" "${12}" "${14}"
        return $?
    fi

    case "$PresentationProfile" in
        main) TitleRole=MainTitle ;;
        master) TitleRole=MasterTitle ;;
        help) TitleRole=HelpTitle ;;
    esac
    build_product_header "$UiWidth" Header || return $?
    printf -v Frame '\033[2J\033[H%s%s%s\n\n%s%s%s\n\n' \
        "${TerminalPalette[ProductHeader]}" "$Header" "${TerminalPalette[Reset]}" \
        "${TerminalPalette[$TitleRole]}" "$Title" "${TerminalPalette[Reset]}"
    if [[ -n "$SummaryConfigName" ]]; then
        SummaryText="$(render_wizard_summary_lines "$SummaryConfigName")" || return $?
        while IFS= read -r SummaryLine || [[ -n "$SummaryLine" ]]; do
            ui_wrap_text "$SummaryLine" "$((UiWidth - 2))" SummaryWrapped || return $?
            printf -v Row '%s\n' "${SummaryWrapped[@]}"
            Frame+="$Row"
        done <<< "$SummaryText"
        Frame+=$'\n'
    fi
    for ((Index=0; Index<${#RenderItems[@]}; Index++)); do
        if [[ -n "$DisabledName" ]]; then
            local -n RenderDisabled="$DisabledName"
            if [[ "${RenderDisabled[Index]:-false}" == true ]]; then
                printf -v Row '%s  %s%s\n' \
                    "${TerminalPalette[EditorDisabled]}" "${RenderItems[Index]}" "${TerminalPalette[Reset]}"
                Frame+="$Row"
                continue
            fi
        fi
        if (( Index == Selected )); then
            printf -v Row '%s> %s%s\n' \
                "${TerminalPalette[EditorSelected]}" "${RenderItems[Index]}" "${TerminalPalette[Reset]}"
        else
            Kind=ordinary
            RawValue=''
            if [[ -n "$KindsName" ]]; then
                local -n RenderKinds="$KindsName"
                Kind="${RenderKinds[Index]:-ordinary}"
            fi
            if [[ -n "$RawValuesName" ]]; then
                local -n RenderRawValues="$RawValuesName"
                RawValue="${RenderRawValues[Index]:-}"
            fi
            RowRole="$(ui_generic_row_palette_role "$Kind" "$RawValue")"
            printf -v Row '%s  %s%s\n' \
                "${TerminalPalette[$RowRole]}" "${RenderItems[Index]}" "${TerminalPalette[Reset]}"
        fi
        Frame+="$Row"
    done
    ui_publish_frame "$Frame"
}

# Назначение: Проверяет, входит ли индекс в переданный список недоступных пунктов.
ui_selection_index_disabled()
{
    local DisabledName="$1"
    local Index="$2"

    [[ -n "$DisabledName" ]] || return 1
    local -n DisabledVector="$DisabledName"
    [[ "${DisabledVector[Index]:-false}" == true ]]
}

# Назначение: Выбирает специализированный renderer по виду surface и связывает общий selection loop с его данными.
# shellcheck disable=SC2034  # UiSelectedOutputRef is a nameref output.
ui_select()
{
    local Title="$1"
    local ItemsName="$2"
    local Initial="$3"
    local -n UiSelectionItemsRef="$ItemsName"
    local -n UiSelectedOutputRef="$4"
    local SummaryConfigName="${5:-}"
    local DisabledName="${6:-}"
    local PresentationProfile="${7:-}"
    local CurrentIndex="$Initial"
    local Key=''
    local SelectionStatus=0
    local AcceleratorName="${15:-${14:-}}"
    local -A DocumentPager=([Current]=0 [Count]=1 [Capacity]=0)
    local -A FormViewport=([Start]=0 [End]=0 [Capacity]=0)

    (( ${#UiSelectionItemsRef[@]} > 0 )) || return 80
    (( CurrentIndex >= 0 && CurrentIndex < ${#UiSelectionItemsRef[@]} )) || CurrentIndex=0
    local Attempts=0
    while ui_selection_index_disabled "$DisabledName" "$CurrentIndex"; do
        CurrentIndex=$(((CurrentIndex + 1) % ${#UiSelectionItemsRef[@]}))
        ((Attempts++))
        (( Attempts < ${#UiSelectionItemsRef[@]} )) || return 80
    done
    enter_terminal_selection_mode || return $?
    while true; do
        ui_render_selection "$Title" "$ItemsName" "$CurrentIndex" "$SummaryConfigName" "$DisabledName" \
            "$PresentationProfile" "${8:-}" "${9:-}" "${10:-}" "${11:-}" "${12:-}" "${13:-}" "${14:-}" DocumentPager FormViewport || {
            SelectionStatus=$?
            break
        }
        ui_read_key Key || {
            SelectionStatus=$?
            break
        }
        case "$Key" in
            up)
                while true; do
                    CurrentIndex=$(((CurrentIndex + ${#UiSelectionItemsRef[@]} - 1) % ${#UiSelectionItemsRef[@]}))
                    ui_selection_index_disabled "$DisabledName" "$CurrentIndex" || break
                done
                ;;
            down)
                while true; do
                    CurrentIndex=$(((CurrentIndex + 1) % ${#UiSelectionItemsRef[@]}))
                    ui_selection_index_disabled "$DisabledName" "$CurrentIndex" || break
                done
                ;;
            page_up)
                if [[ "$PresentationProfile" == document ]] && (( DocumentPager[Current] > 0 )); then
                    DocumentPager[Current]=$((DocumentPager[Current] - 1))
                fi
                ;;
            page_down)
                if [[ "$PresentationProfile" == document ]] &&
                   (( DocumentPager[Current] + 1 < DocumentPager[Count] )); then
                    DocumentPager[Current]=$((DocumentPager[Current] + 1))
                fi
                ;;
            enter) UiSelectedOutputRef="$CurrentIndex"; break ;;
            digit:*)
                if [[ -n "$AcceleratorName" ]]; then
                    local -n AcceleratorMap="$AcceleratorName"
                    local Digit="${Key#digit:}"
                    if [[ -n "${AcceleratorMap[$Digit]+x}" ]] &&
                       ! ui_selection_index_disabled "$DisabledName" "${AcceleratorMap[$Digit]}"; then
                        UiSelectedOutputRef="${AcceleratorMap[$Digit]}"
                        break
                    fi
                fi
                ;;
            *) : ;;
        esac
    done
    restore_terminal_state || return 31
    return "$SelectionStatus"
}

# Назначение: Показывает prompt на tty, читает строку и возвращает её через nameref с восстановлением режима.
# shellcheck disable=SC2034  # ValueOut is a nameref output.
ui_read_line()
{
    local Prompt="$1"
    local Secret="$2"
    local -n ValueOut="$3"

    restore_terminal_state || return 31
    printf '%s: ' "$Prompt"
    ValueOut=''
    if [[ "$Secret" == true ]]; then
        IFS= read -r -s ValueOut <&0 || { printf '\n'; return 1; }
        printf '\n'
    else
        IFS= read -r ValueOut <&0 || return 1
    fi
    return 0
}

# Назначение: Редактирует секрет посимвольно, отображая только маску и поддерживая backspace/cancel/accept.
# shellcheck disable=SC2034  # ValueOut is a nameref output.
ui_edit_secret_in_place()
{
    local Prompt="$1"
    local InitialValue="$2"
    local -n ValueOut="$3"
    local Character=''
    local Mask=''

    restore_terminal_state || return 31
    ValueOut="$InitialValue"
    enter_terminal_secret_mode || return $?
    while true; do
        printf -v Mask '%*s' "${#ValueOut}" ''
        Mask="${Mask// /*}"
        printf '\r\033[2K%s: %s' "$Prompt" "$Mask"
        IFS= read -r -n 1 Character <&0 || {
            restore_terminal_state || :
            printf '\n'
            return 2
        }
        case "$Character" in
            $'\n'|$'\r'|'') break ;;
            $'\004')
                restore_terminal_state || :
                printf '\n'
                return 2
                ;;
            $'\177'|$'\b')
                ((${#ValueOut} > 0)) && ValueOut="${ValueOut:0:${#ValueOut}-1}"
                ;;
            [$'\001'-$'\037']) ;;
            *) ValueOut+="$Character" ;;
        esac
    done
    restore_terminal_state || return 31
    printf '\n'
    return 0
}

# Назначение: Показывает модальное локализованное сообщение и ожидает подтверждения пользователя.
ui_message_text()
{
    local Key="$1"
    local Message=''

    localized_message "$Key" Message
    printf '%s\n' "$Message"
    return 0
}

# ==============================================================================
# Configuration Editor
# ==============================================================================

# Назначение: Определяет доступность поля Editor по staged родительским переключателям.
editor_field_applicable()
{
    local ConfigName="$1"
    local Field="$2"
    local -n EditorApplicableConfig="$ConfigName"

    if [[ "$Field" == OxidizedHome && "${EditorApplicableConfig[UseOxidized]}" != true ]]; then
        return 1
    fi
    case "${EditorApplicableConfig[backup_type]}:$Field" in
        configuration:encrypt|configuration:clear_dns_cache|configuration:clear_console_history|binary:export_format|binary:show_sensitive) return 1 ;;
        *) return 0 ;;
    esac
}

# Назначение: Проверяет staged-набор целиком и применяет те же контекстные resets, что effective-конфигурация.
validate_editor_staged_config()
{
    local ConfigName="$1"
    local -n EditorConfigToValidate="$ConfigName"
    local Key=''
    local Validated=''

    for Key in Language SshPort UseOxidized OxidizedHome UseIdentityName backup_type UseIncremental export_format show_sensitive encrypt clear_dns_cache clear_console_history BackupRoot UseNetFolder MonthlyArchive LogLevel MainLogPath; do
        validate_ordinary_config_value \
            "$Key" "${EditorConfigToValidate[$Key]:-}" Validated || return 1
    done
    return 0
}

# Назначение: Редактирует одно staged-поле подходящим boolean/day/language/path/input контролом.
editor_edit_field()
{
    local ConfigName="$1"
    local Field="$2"
    local ChangedOutName="${3:-}"
    local -n EditorFieldConfig="$ConfigName"
    local Candidate=''
    local Validated=''
    local Previous="${EditorFieldConfig[$Field]}"
    local Prompt=''
    local FieldLabel=''
    local PreviewStatus=0

    [[ -z "$ChangedOutName" ]] || printf -v "$ChangedOutName" '%s' false

    localized_field_label "$Field" FieldLabel || return $?

    case "$Field" in
        Language)
            next_editor_language_code "$Previous" Candidate || return $?
            ;;
        UseOxidized|UseIdentityName|UseNetFolder|UseIncremental|show_sensitive|clear_dns_cache|clear_console_history)
            [[ "$Previous" == true ]] && Candidate=false || Candidate=true
            ;;
        backup_type)
            case "$Previous" in
                configuration) Candidate=binary ;;
                binary) Candidate=both ;;
                *) Candidate=configuration ;;
            esac
            ;;
        export_format)
            case "$Previous" in
                compact) Candidate=terse ;;
                terse) Candidate=verbose ;;
                *) Candidate=compact ;;
            esac
            ;;
        LogLevel)
            case "$Previous" in
                0) Candidate=1 ;;
                1) Candidate=2 ;;
                2) Candidate=3 ;;
                *) Candidate=0 ;;
            esac
            ;;
        encrypt)
            localized_message input_prompt Prompt
            ui_edit_secret_in_place "$Prompt ($FieldLabel)" "$Previous" Candidate || return 2
            ;;
        *)
            localized_message input_prompt Prompt
            while true; do
                ui_read_line "$Prompt ($FieldLabel)" \
                    "$([[ "$Field" == encrypt ]] && printf true || printf false)" \
                    Candidate || return 2
                if validate_ordinary_config_value "$Field" "$Candidate" Validated; then
                    Candidate="$Validated"
                    break
                fi
                ui_message_text invalid_input
            done
            ;;
    esac
    EditorFieldConfig["$Field"]="$Candidate"
    apply_config_context_resets "$ConfigName" "$Field" || return $?
    if ! validate_editor_staged_config "$ConfigName"; then
        EditorFieldConfig["$Field"]="$Previous"
        ui_message_text invalid_input
        return 1
    fi
    if [[ "$Field" == Language ]]; then
        PreviewStatus=0
        preview_presentation_language "$Candidate" || PreviewStatus=$?
        if (( PreviewStatus != 0 )); then
            EditorFieldConfig["$Field"]="$Previous"
            return "$PreviewStatus"
        fi
    fi
    if [[ "$Candidate" != "$Previous" && -n "$ChangedOutName" ]]; then
        printf -v "$ChangedOutName" '%s' true
    fi
    return 0
}

# Назначение: Ведёт цикл формы Editor, сохраняет только валидный staged-набор или отменяет без публикации.
# shellcheck disable=SC2034  # EditorCommittedOut is a nameref transaction output.
run_configuration_editor_session()
{
    local InMenu="${1:-false}"
    local -n EditorCommittedOut="$2"
    local Title=''
    local SaveLabel=''
    local CancelLabel=''
    local DiscardTitle=''
    local YesLabel=''
    local NoLabel=''
    local Selected=0
    local Choice=0
    local Dirty=false
    local Key=''
    local FieldLabel=''
    local Status=0
    local FieldChanged=false
    local -A StagedConfig=()
    local DisplayValue=''
    local -a Fields=(Language UseOxidized OxidizedHome UseIdentityName backup_type UseIncremental export_format show_sensitive encrypt clear_dns_cache clear_console_history BackupRoot UseNetFolder MonthlyArchive LogLevel MainLogPath)
    local -a Items=()
    local -a DiscardItems=()
    local -a DiscardKinds=(boolean boolean)
    local -a DiscardRawValues=(true false)
    local -a DisabledItems=()
    local -a EditorLabels=()
    local -a EditorValues=()
    # Metadata arrays are consumed dynamically through editor-renderer namerefs.
    # shellcheck disable=SC2034
    local -a EditorKinds=(ordinary boolean path boolean ordinary boolean ordinary boolean ordinary boolean boolean path boolean ordinary ordinary path action action)
    local -a EditorRawValues=()
    local -a EditorDescriptions=()
    local Description=''
    local SaveDescription=''
    local CancelDescription=''

    : "$InMenu"
    EditorCommittedOut=false
    for Key in "${!DefaultValues[@]}"; do
        StagedConfig["$Key"]="${DefaultValues[$Key]}"
    done
    if [[ "${RuntimeState[StartupConfigExists]:-false}" == true ]]; then
        for Key in "${!ParsedOptionConfig[@]}"; do
            StagedConfig["$Key"]="${ParsedOptionConfig[$Key]}"
        done
    fi
    while true; do
        localized_message editor_title Title
        localized_message editor_save SaveLabel
        localized_message editor_cancel CancelLabel
        localized_field_description Save SaveDescription || return $?
        localized_field_description Cancel CancelDescription || return $?
        Items=()
        DisabledItems=()
        EditorLabels=()
        EditorValues=()
        EditorRawValues=()
        EditorDescriptions=()
        for Key in "${Fields[@]}"; do
            localized_field_label "$Key" FieldLabel || return $?
            localized_config_display_value "$Key" "${StagedConfig[$Key]}" DisplayValue || return $?
            localized_field_description "$Key" Description || return $?
            Items+=("$FieldLabel=$DisplayValue")
            EditorLabels+=("$FieldLabel")
            EditorValues+=("$DisplayValue")
            EditorRawValues+=("${StagedConfig[$Key]}")
            EditorDescriptions+=("$Description")
            if editor_field_applicable StagedConfig "$Key"; then
                DisabledItems+=(false)
            else
                DisabledItems+=(true)
            fi
        done
        Items+=("$SaveLabel" "$CancelLabel")
        DisabledItems+=(false false)
        EditorLabels+=("$SaveLabel" "$CancelLabel")
        EditorValues+=('' '')
        EditorRawValues+=('' '')
        EditorDescriptions+=("$SaveDescription" "$CancelDescription")
        Status=0
        ui_select "$Title" Items "$Selected" Choice '' DisabledItems editor \
            EditorLabels EditorValues EditorKinds EditorRawValues EditorDescriptions "${#Fields[@]}" || Status=$?
        (( Status == 31 )) && return 31
        (( Status == 0 )) || return 0
        Selected="$Choice"
        if (( Choice < ${#Fields[@]} )); then
            Status=0
            FieldChanged=false
            editor_edit_field StagedConfig "${Fields[Choice]}" FieldChanged || Status=$?
            if (( Status == 0 )) && [[ "$FieldChanged" == true ]]; then
                Dirty=true
            fi
            continue
        fi
        if (( Choice == ${#Fields[@]} )); then
            if write_canonical_option_config \
                "${RuntimeState[OptionConfigPath]}" StagedConfig; then
                EditorCommittedOut=true
                return 0
            fi
            ui_message_text save_failed
            continue
        fi
        if [[ "$Dirty" != true ]]; then
            return 0
        fi
        localized_message editor_discard DiscardTitle
        localized_message yes YesLabel
        localized_message no NoLabel
        DiscardItems=("$YesLabel" "$NoLabel")
        : "${DiscardItems[@]}"
        Choice=0
        ui_select "$DiscardTitle" DiscardItems 1 Choice '' '' '' \
            DiscardKinds DiscardRawValues || return 0
        (( Choice == 0 )) && return 0
    done
}

# Назначение: Загружает startup/default значения, запускает Editor в terminal wrapper и публикует выбранную конфигурацию.
run_configuration_editor()
{
    local InMenu="${1:-false}"
    local OriginalPresentationLanguage="${RuntimeState[PresentationLanguage]:-en}"
    local CatalogKey=''
    local Status=0
    local Committed=false
    local -A OriginalPresentationMessages=()

    for CatalogKey in "${!PresentationMessages[@]}"; do
        OriginalPresentationMessages["$CatalogKey"]="${PresentationMessages[$CatalogKey]}"
    done
    run_configuration_editor_session "$InMenu" Committed || Status=$?
    if [[ "$Committed" != true || "${CliState[LanguageProvided]:-false}" == true ]]; then
        PresentationMessages=()
        for CatalogKey in "${!OriginalPresentationMessages[@]}"; do
            PresentationMessages["$CatalogKey"]="${OriginalPresentationMessages[$CatalogKey]}"
        done
        RuntimeState[PresentationLanguage]="$OriginalPresentationLanguage"
    fi
    return "$Status"
}

# ==============================================================================
# BackUP Master
# ==============================================================================

# Назначение: Возвращает подпись поля Master, включая специальные connection-поля вне общего config mapping.
# shellcheck disable=SC2034  # LabelOut is a nameref output.
localized_master_field_label()
{
    local Field="$1"
    local OutputName="$2"
    local MessageKey=''

    case "$Field" in
        DeviceName) MessageKey=master_field_device_name ;;
        Address) MessageKey=master_field_address ;;
        User) MessageKey=master_field_user ;;
        Password) MessageKey=master_field_password ;;
        SshPort) MessageKey=master_field_ssh_port ;;
        backup_type) MessageKey=master_field_backup_type ;;
        UseIncremental) MessageKey=master_field_use_incremental ;;
        export_format) MessageKey=master_field_export_format ;;
        show_sensitive) MessageKey=master_field_show_sensitive ;;
        encrypt) MessageKey=master_field_encrypt ;;
        clear_dns_cache) MessageKey=master_field_clear_dns_cache ;;
        clear_console_history) MessageKey=master_field_clear_console_history ;;
        BackupRoot) MessageKey=master_field_backup_root ;;
        UseNetFolder) MessageKey=master_field_use_net_folder ;;
        UseIdentityName) MessageKey=master_field_use_identity_name ;;
        *) return 80 ;;
    esac
    localized_message "$MessageKey" "$OutputName"
}

# Назначение: Возвращает контекстное описание выбранного поля или действия Master.
# shellcheck disable=SC2034  # DescriptionOut is a nameref output.
localized_master_description()
{
    local Identity="$1"
    local OutputName="$2"
    local MessageKey=''

    case "$Identity" in
        DeviceName) MessageKey=master_description_device_name ;;
        Address) MessageKey=master_description_address ;;
        User) MessageKey=master_description_user ;;
        Password) MessageKey=master_description_password ;;
        SshPort) MessageKey=master_description_ssh_port ;;
        execute) MessageKey=master_description_execute ;;
        save) MessageKey=master_description_save ;;
        copy) MessageKey=master_description_copy ;;
        return) MessageKey=master_description_return ;;
        *)
            localized_field_description "$Identity" "$OutputName"
            return $?
            ;;
    esac
    localized_message "$MessageKey" "$OutputName"
}

# Назначение: Сопоставляет внутреннее действие Master локализованной кнопке execute/save/copy/return.
# shellcheck disable=SC2034  # LabelOut is a nameref output.
localized_master_action_label()
{
    local Action="$1"
    local OutputName="$2"
    local MessageKey=''

    case "$Action" in
        execute) MessageKey=master_execute ;;
        save) MessageKey=master_save_device ;;
        copy) MessageKey=master_copy_cli ;;
        return) MessageKey=master_return ;;
        *) return 80 ;;
    esac
    localized_message "$MessageKey" "$OutputName"
}

# Назначение: Добавляет проверенную single-запись в DeviceList через полную безопасную атомарную перепубликацию.
master_save_device_list()
{
    local ConfigName="$1"
    local -n MasterConfig="$ConfigName"
    local Path="${RuntimeState[DeviceListPath]}"
    local DeviceId=''
    local TargetId=''
    local NameMatch=''
    local EndpointMatch=''
    local CandidateKey=''
    local ExistingKey=''
    local InputPort=''
    local EffectivePort="${MasterConfig[SshPort]}"
    local Status=0

    [[ -n "${MasterConfig[DeviceName]:-}" &&
       -n "${MasterConfig[Address]:-}" &&
       -n "${MasterConfig[User]:-}" &&
       -n "${MasterConfig[Password]:-}" ]] || return 23
    master_field_valid SshPort "$EffectivePort" || return 23
    if [[ "$EffectivePort" != "${DefaultValues[SshPort]}" ]]; then
        InputPort="$EffectivePort"
    fi
    # Keep the common record parser on the staged Master port while it compares
    # and validates deliberately omitted/default ports in this transaction.
    EffectiveConfig[SshPort]="$EffectivePort"
    if [[ -e "$Path" || -L "$Path" ]]; then
        load_canonical_device_list "$Path" master_update || Status=$?
        (( Status == 0 )) || return "$Status"
        if (( SourceStats[Skipped] != 0 )); then
            reset_device_collection
            return 23
        fi
    else
        reset_device_collection
    fi

    device_duplicate_key CandidateKey \
        "${MasterConfig[Address]}" "${MasterConfig[User]}" \
        "${MasterConfig[Password]}" "$EffectivePort"
    for DeviceId in "${DeviceIds[@]}"; do
        local -n ExistingMasterDevice="$DeviceId"
        device_duplicate_key ExistingKey \
            "${ExistingMasterDevice[Address]}" "${ExistingMasterDevice[User]}" \
            "${ExistingMasterDevice[Password]}" "${ExistingMasterDevice[Port]}"
        if [[ "${ExistingMasterDevice[DeclaredName]}" == "${MasterConfig[DeviceName]}" ]]; then
            [[ -z "$NameMatch" ]] || { reset_device_collection; return 23; }
            NameMatch="$DeviceId"
        fi
        if [[ "$ExistingKey" == "$CandidateKey" ]]; then
            [[ -z "$EndpointMatch" ]] || { reset_device_collection; return 23; }
            EndpointMatch="$DeviceId"
        fi
    done
    if [[ -n "$EndpointMatch" && "$EndpointMatch" != "$NameMatch" ]]; then
        reset_device_collection
        return 23
    fi
    TargetId="$NameMatch"

    for DeviceId in "${DeviceIds[@]}"; do
        [[ "$DeviceId" == "$TargetId" ]] && continue
        local -n OtherMasterDevice="$DeviceId"
        device_duplicate_key ExistingKey \
            "${OtherMasterDevice[Address]}" "${OtherMasterDevice[User]}" \
            "${OtherMasterDevice[Password]}" "${OtherMasterDevice[Port]}"
        if [[ "${OtherMasterDevice[DeclaredName]}" == "${MasterConfig[DeviceName]}" ||
              "$ExistingKey" == "$CandidateKey" ]]; then
            reset_device_collection
            return 23
        fi
    done

    if [[ -z "$TargetId" ]]; then
        RuntimeState[DeviceContextCounter]="$((${RuntimeState[DeviceContextCounter]:-0} + 1))"
        TargetId="DeviceContext_${RuntimeState[DeviceContextCounter]}"
        declare -gA "$TargetId=()"
        DeviceIds+=("$TargetId")
    fi
    local -n SavedMasterDevice="$TargetId"
    SavedMasterDevice[DeclaredName]="${MasterConfig[DeviceName]}"
    SavedMasterDevice[Address]="${MasterConfig[Address]}"
    SavedMasterDevice[User]="${MasterConfig[User]}"
    SavedMasterDevice[Password]="${MasterConfig[Password]}"
    SavedMasterDevice[Port]="$EffectivePort"
    SavedMasterDevice[InputUser]="${MasterConfig[User]}"
    SavedMasterDevice[InputPassword]="${MasterConfig[Password]}"
    SavedMasterDevice[InputPort]="$InputPort"
    SavedMasterDevice[SourceType]=master
    # The generated writer consumes this dynamic context through DeviceIds.
    # shellcheck disable=SC2034
    SavedMasterDevice[SourceLine]=0
    write_generated_device_list "$Path" || Status=$?
    reset_device_collection
    return "$Status"
}

# Назначение: Строит shell-quoted CLI-команду, эквивалентную staged Master-настройкам, для показа/копирования.
# shellcheck disable=SC2034  # CommandOut is an optional nameref output.
render_master_cli_command()
{
    local ConfigName="$1"
    local OutputName="${2:-}"
    local -n MasterConfig="$ConfigName"
    local Argument=''
    local BuiltCommand='./mikrotik-backup.sh'
    local -a Arguments=(
        "-a=${MasterConfig[Address]}"
        "-u=${MasterConfig[User]}"
        "-p=${MasterConfig[Password]}"
    )

    if [[ "${MasterConfig[UseIdentityName]}" == false &&
          -n "${MasterConfig[DeviceName]:-}" ]]; then
        Arguments+=(--device-name "${MasterConfig[DeviceName]}")
    fi
    [[ "${MasterConfig[SshPort]}" != "${DefaultValues[SshPort]}" ]] &&
        Arguments+=(--port "${MasterConfig[SshPort]}")
    [[ "${MasterConfig[backup_type]}" != "${DefaultValues[backup_type]}" ]] &&
        Arguments+=(--backup-type "${MasterConfig[backup_type]}")
    if master_field_applicable "$ConfigName" export_format &&
       [[ "${MasterConfig[export_format]}" != "${DefaultValues[export_format]}" ]]; then
        Arguments+=(--export-format "${MasterConfig[export_format]}")
    fi
    if master_field_applicable "$ConfigName" show_sensitive &&
       [[ "${MasterConfig[show_sensitive]}" != "${DefaultValues[show_sensitive]}" ]]; then
        Arguments+=(--show-sensitive "${MasterConfig[show_sensitive]}")
    fi
    if master_field_applicable "$ConfigName" encrypt &&
       [[ "${MasterConfig[encrypt]}" != "${DefaultValues[encrypt]}" ]]; then
        Arguments+=(--encrypt "${MasterConfig[encrypt]}")
    fi
    if master_field_applicable "$ConfigName" clear_dns_cache &&
       [[ "${MasterConfig[clear_dns_cache]}" != "${DefaultValues[clear_dns_cache]}" ]]; then
        Arguments+=(--clear-dns-cache "${MasterConfig[clear_dns_cache]}")
    fi
    if master_field_applicable "$ConfigName" clear_console_history &&
       [[ "${MasterConfig[clear_console_history]}" != "${DefaultValues[clear_console_history]}" ]]; then
        Arguments+=(--clear-console-history "${MasterConfig[clear_console_history]}")
    fi
    [[ "${MasterConfig[BackupRoot]}" != "${DefaultValues[BackupRoot]}" ]] &&
        Arguments+=(--backup-root "${MasterConfig[BackupRoot]}")
    [[ "${MasterConfig[UseNetFolder]}" != "${DefaultValues[UseNetFolder]}" ]] &&
        Arguments+=(--use-net-folder "${MasterConfig[UseNetFolder]}")
    [[ "${MasterConfig[UseIdentityName]}" != "${DefaultValues[UseIdentityName]}" ]] &&
        Arguments+=(--use-identity-name "${MasterConfig[UseIdentityName]}")

    for Argument in "${Arguments[@]}"; do
        printf -v Argument '%q' "$Argument"
        BuiltCommand+=" $Argument"
    done
    if [[ -n "$OutputName" ]]; then
        local -n CommandOut="$OutputName"
        CommandOut="$BuiltCommand"
    else
        printf '%s\n' "$BuiltCommand"
    fi
    return 0
}

# Назначение: Кодирует сгенерированную команду base64 и отправляет её в clipboard через OSC 52 только по явному действию.
master_emit_osc52_command()
{
    local Command="$1"
    local Payload=''

    command -v base64 >/dev/null 2>&1 || return 30
    Payload="$(printf '%s' "$Command" | base64 --wrap=0)" || return 30
    [[ -n "$Payload" ]] || return 80
    restore_terminal_state || return 31
    printf '\033]52;c;%s\a' "$Payload"
    return 0
}

# Назначение: Проверяет одно поле Master с учётом connection-реквизитов и общего config validator.
master_field_valid()
{
    local Field="$1"
    local Value="$2"
    local Validated=''

    case "$Field" in
        DeviceName|Address|User|Password) [[ -n "$Value" && "$Value" != *$'\t'* ]] ;;
        SshPort|BackupRoot|UseNetFolder|UseIdentityName|backup_type|UseIncremental|export_format|show_sensitive|encrypt|clear_dns_cache|clear_console_history)
            validate_ordinary_config_value "$Field" "$Value" Validated
            ;;
        *) return 80 ;;
    esac
}

# Назначение: Определяет применимость поля Master по staged backup_type и родительским переключателям.
master_field_applicable()
{
    local ConfigName="$1"
    local Field="$2"
    local -n ApplicableConfig="$ConfigName"

    case "${ApplicableConfig[backup_type]}:$Field" in
        configuration:encrypt|configuration:clear_dns_cache|configuration:clear_console_history|binary:export_format|binary:show_sensitive) return 1 ;;
        *) return 0 ;;
    esac
}

# Назначение: Создаёт staged Master-модель из defaults/effective значений без изменения runtime-конфигурации.
# shellcheck disable=SC2034  # Staged values are returned through a nameref.
initialize_master_staged_config()
{
    local -n MasterConfigOut="$1"
    local Field=''

    MasterConfigOut=()
    MasterConfigOut[DeviceName]=''
    MasterConfigOut[Address]=''
    MasterConfigOut[User]=''
    MasterConfigOut[Password]=''
    for Field in SshPort backup_type UseIncremental export_format show_sensitive encrypt clear_dns_cache clear_console_history BackupRoot UseNetFolder UseIdentityName; do
        MasterConfigOut["$Field"]="${DefaultValues[$Field]}"
    done
    MasterConfigOut[UseIncremental]="${ParsedOptionConfig[UseIncremental]:-${DefaultValues[UseIncremental]}}"
    for Field in "${MasterFields[@]}"; do
        [[ "${CliState[${Field}Provided]:-false}" == true ]] || continue
        MasterConfigOut["$Field"]="${CliState[$Field]}"
    done
    apply_config_context_resets "$1" backup_type || return $?
    return 0
}

# Назначение: Проверяет, достаточно ли address/user/password для сохранения либо запуска single device.
master_device_record_ready()
{
    local ConfigName="$1"
    local -n ReadyConfig="$ConfigName"
    local Field=''

    for Field in DeviceName Address User Password SshPort; do
        master_field_valid "$Field" "${ReadyConfig[$Field]:-}" || return 1
    done
    return 0
}

# Назначение: Требует готовую запись устройства и валидные применимые настройки перед Execute.
master_execution_ready()
{
    local ConfigName="$1"
    local -n ReadyConfig="$ConfigName"
    local Field=''

    for Field in Address User Password SshPort backup_type UseIncremental BackupRoot UseNetFolder UseIdentityName; do
        master_field_valid "$Field" "${ReadyConfig[$Field]:-}" || return 1
    done
    if [[ "${ReadyConfig[UseIdentityName]}" == false ]]; then
        master_field_valid DeviceName "${ReadyConfig[DeviceName]:-}" || return 1
    fi
    for Field in export_format show_sensitive encrypt clear_dns_cache clear_console_history; do
        master_field_applicable "$ConfigName" "$Field" || continue
        master_field_valid "$Field" "${ReadyConfig[$Field]:-}" || return 1
    done
    return 0
}

# Назначение: Форматирует staged-значение для формы Master, маскируя оба password-поля.
# shellcheck disable=SC2034  # DisplayOut is a nameref output.
master_display_value()
{
    local Field="$1"
    local RawValue="$2"
    local OutputName="$3"
    local -n MasterDisplayOut="$OutputName"

    if [[ "$Field" == Password || "$Field" == encrypt ]]; then
        printf -v MasterDisplayOut '%*s' "${#RawValue}" ''
        MasterDisplayOut="${MasterDisplayOut// /*}"
        return 0
    fi
    localized_config_display_value "$Field" "$RawValue" "$OutputName"
}

# Назначение: Возвращает вид редактора поля Master: secret, choice, path или обычная строка.
master_field_kind()
{
    local Field="$1"

    case "$Field" in
        show_sensitive|clear_dns_cache|clear_console_history|UseNetFolder|UseIdentityName|UseIncremental) printf '%s' boolean ;;
        BackupRoot) printf '%s' path ;;
        *) printf '%s' ordinary ;;
    esac
    return 0
}

# Назначение: Строит параллельные labels/values/descriptions/disabled индексы для текущего кадра Master.
# shellcheck disable=SC2034  # Form vectors are returned through namerefs.
master_build_form_vectors()
{
    local ConfigName="$1"
    local -n ItemsOut="$2"
    local -n DisabledOut="$3"
    local -n LabelsOut="$4"
    local -n ValuesOut="$5"
    local -n KindsOut="$6"
    local -n RawValuesOut="$7"
    local -n DescriptionsOut="$8"
    local -n FormConfig="$ConfigName"
    local Field=''
    local Action=''
    local Label=''
    local Display=''
    local Description=''
    local ExecuteReady=false
    local SaveReady=false

    master_execution_ready "$ConfigName" && ExecuteReady=true
    master_device_record_ready "$ConfigName" && SaveReady=true
    ItemsOut=()
    DisabledOut=()
    LabelsOut=()
    ValuesOut=()
    KindsOut=()
    RawValuesOut=()
    DescriptionsOut=()
    for Field in "${MasterFields[@]}"; do
        localized_master_field_label "$Field" Label || return $?
        master_display_value "$Field" "${FormConfig[$Field]:-}" Display || return $?
        localized_master_description "$Field" Description || return $?
        ItemsOut+=("$Label=$Display")
        LabelsOut+=("$Label")
        ValuesOut+=("$Display")
        KindsOut+=("$(master_field_kind "$Field")")
        RawValuesOut+=("${FormConfig[$Field]:-}")
        DescriptionsOut+=("$Description")
        if master_field_applicable "$ConfigName" "$Field"; then
            DisabledOut+=(false)
        else
            DisabledOut+=(true)
        fi
    done
    for Action in "${MasterActions[@]}"; do
        localized_master_action_label "$Action" Label || return $?
        localized_master_description "$Action" Description || return $?
        ItemsOut+=("$Label")
        LabelsOut+=("$Label")
        ValuesOut+=('')
        KindsOut+=(action)
        RawValuesOut+=('')
        DescriptionsOut+=("$Description")
        case "$Action" in
            execute|copy) [[ "$ExecuteReady" == true ]] && DisabledOut+=(false) || DisabledOut+=(true) ;;
            save) [[ "$SaveReady" == true ]] && DisabledOut+=(false) || DisabledOut+=(true) ;;
            return) DisabledOut+=(false) ;;
        esac
    done
    return 0
}

# Назначение: Изменяет выбранное staged-поле Master через соответствующий input/selector без преждевременного запуска.
master_edit_field()
{
    local ConfigName="$1"
    local Field="$2"
    local -n WizardFieldConfig="$ConfigName"
    local Candidate=''
    local Validated=''
    local Prompt=''
    local FieldLabel=''

    localized_master_field_label "$Field" FieldLabel || return $?
    case "$Field" in
        UseNetFolder|UseIdentityName|UseIncremental|show_sensitive|clear_dns_cache|clear_console_history)
            [[ "${WizardFieldConfig[$Field]}" == true ]] && Candidate=false || Candidate=true
            ;;
        backup_type)
            case "${WizardFieldConfig[$Field]}" in
                configuration) Candidate=binary ;;
                binary) Candidate=both ;;
                *) Candidate=configuration ;;
            esac
            ;;
        export_format)
            case "${WizardFieldConfig[$Field]}" in
                compact) Candidate=terse ;;
                terse) Candidate=verbose ;;
                *) Candidate=compact ;;
            esac
            ;;
        Password|encrypt)
            localized_message input_prompt Prompt
            while true; do
                ui_edit_secret_in_place "$Prompt ($FieldLabel)" \
                    "${WizardFieldConfig[$Field]}" Candidate || return 2
                if master_field_valid "$Field" "$Candidate"; then
                    break
                fi
                ui_message_text invalid_input
            done
            ;;
        *)
            localized_message input_prompt Prompt
            while true; do
                ui_read_line "$Prompt ($FieldLabel)" false Candidate || return 2
                [[ -z "$Candidate" ]] && Candidate="${WizardFieldConfig[$Field]}"
                if master_field_valid "$Field" "$Candidate"; then
                    if validate_ordinary_config_value "$Field" "$Candidate" Validated; then
                        Candidate="$Validated"
                    fi
                    break
                fi
                ui_message_text invalid_input
            done
            ;;
    esac
    WizardFieldConfig["$Field"]="$Candidate"
    apply_config_context_resets "$ConfigName" "$Field" || return $?
    return 0
}

# Назначение: Собирает локализованную сводку параметров предстоящего single backup с маскировкой секретов.
render_wizard_summary_lines()
{
    local ConfigName="$1"
    local -n WizardSummaryConfig="$ConfigName"
    local SetLabel=''
    local Field=''
    local FieldLabel=''
    local Value=''
    local -a Fields=(DeviceName Address User Password backup_type UseIncremental export_format show_sensitive encrypt clear_dns_cache clear_console_history BackupRoot UseIdentityName MonthlyArchive)

    localized_message value_set SetLabel
    for Field in "${Fields[@]}"; do
        localized_field_label "$Field" FieldLabel || return $?
        localized_config_display_value "$Field" "${WizardSummaryConfig[$Field]}" Value || return $?
        [[ "$Field" == Password ]] && Value="$SetLabel"
        printf '%s: %s\n' "$FieldLabel" "$Value"
    done
    return 0
}

# Назначение: Показывает итоговую сводку Master и запрашивает подтверждение Execute.
render_wizard_summary()
{
    local ConfigName="$1"
    local Title=''
    local Header=''
    local Summary=''
    local Frame=''

    localized_message wizard_summary Title
    build_product_header "$UiWidth" Header || return $?
    Summary="$(render_wizard_summary_lines "$ConfigName")" || return $?
    printf -v Frame '\033[2J\033[H%s%s%s\n\n%s%s%s\n\n%s\n' \
        "${TerminalPalette[ProductHeader]}" "$Header" "${TerminalPalette[Reset]}" \
        "${TerminalPalette[MasterTitle]}" "$Title" "${TerminalPalette[Reset]}" "$Summary"
    ui_publish_frame "$Frame"
}

# Назначение: Материализует staged Master-настройки в isolated single execution и возвращает реальный pipeline result.
master_execute_single_backup()
{
    local ConfigName="$1"
    local -n WizardExecutionConfig="$ConfigName"
    local Key=''

    copy_defaults_to_effective_config
    for Key in LogLevel MainLogPath; do
        EffectiveConfig["$Key"]="${ParsedOptionConfig[$Key]:-${DefaultValues[$Key]}}"
        if [[ "${CliState[${Key}Provided]:-false}" == true ]]; then
            EffectiveConfig["$Key"]="${CliState[$Key]}"
        fi
    done
    for Key in DeviceName Address User Password SshPort backup_type UseIncremental export_format show_sensitive encrypt clear_dns_cache clear_console_history BackupRoot UseNetFolder UseIdentityName; do
        if [[ "$Key" == Password ]]; then
            EffectiveConfig[DevicePassword]="${WizardExecutionConfig[$Key]}"
        else
            EffectiveConfig["$Key"]="${WizardExecutionConfig[$Key]}"
        fi
    done
    EffectiveConfig[Language]="${RuntimeState[PresentationLanguage]}"
    EffectiveConfig[MonthlyArchive]=false
    EffectiveConfig[UseOxidized]=false
    ExecutionIntent[Kind]=single
    run_configured_execution
}

# Назначение: Ведёт цикл полей/действий Master, различая Execute, Save, Copy и Return и фиксируя факт запуска.
# shellcheck disable=SC2034  # Master vectors are consumed through dynamic namerefs.
run_backup_master()
{
    local Title=''
    local Choice=0
    local Selected=0
    local Status=0
    local ActionIndex=0
    local Command=''
    local -A WizardConfig=()
    local -A Accelerators=([1]=15 [2]=16 [3]=17 [0]=18)
    local -a Items=()
    local -a DisabledItems=()
    local -a Labels=()
    local -a Values=()
    local -a Kinds=()
    local -a RawValues=()
    local -a Descriptions=()

    RuntimeState[WizardExecuted]=false
    RuntimeState[WizardExitRequested]=false
    initialize_master_staged_config WizardConfig || return $?
    while true; do
        localized_message wizard_title Title
        master_build_form_vectors WizardConfig Items DisabledItems Labels Values \
            Kinds RawValues Descriptions || return $?
        Status=0
        ui_select "$Title" Items "$Selected" Choice '' DisabledItems master_form \
            Labels Values Kinds RawValues Descriptions "${#MasterFields[@]}" \
            Accelerators || Status=$?
        (( Status == 0 )) || return "$Status"
        Selected="$Choice"
        if (( Choice < ${#MasterFields[@]} )); then
            master_edit_field WizardConfig "${MasterFields[Choice]}" || return 0
            continue
        fi
        ActionIndex=$((Choice - ${#MasterFields[@]}))
        case "${MasterActions[ActionIndex]}" in
            execute)
                RuntimeState[WizardExecuted]=true
                Status=0
                master_execute_single_backup WizardConfig || Status=$?
                return "$Status"
                ;;
            save)
                Status=0
                master_save_device_list WizardConfig || Status=$?
                : "$Status"
                ;;
            copy)
                render_master_cli_command WizardConfig Command || return $?
                RuntimeState[WizardExitRequested]=true
                master_emit_osc52_command "$Command"
                return $?
                ;;
            return) return 0 ;;
        esac
    done
}

# Назначение: Запускает Master из CLI как самостоятельную поверхность и печатает summary только после Execute.
run_standalone_backup_master()
{
    local Status=0

    run_terminal_ui run_backup_master || Status=$?
    if [[ "${RuntimeState[WizardExecuted]:-false}" == true ]]; then
        emit_backup_result_summary "$Status" || return 80
    fi
    return "$Status"
}

# ==============================================================================
# CLI Help and Usage Instruction
# ==============================================================================

# Назначение: Задаёт структурированные секции, строки и стили Help как единый источник console и UI представлений.
# shellcheck disable=SC2034  # Ordered semantic vectors are returned through namerefs.
build_cli_help_definition()
{
    local -n RolesOut="$1"
    local -n KeysOut="$2"

    RolesOut=(
        code text blank
        heading code code code code code blank
        heading code code code code code code code code code code code code code code code code code code code code blank
        blank
    )
    KeysOut=(
        help_usage help_long_option_forms ''
        help_actions_title help_action_i help_action_b help_action_e help_action_help help_action_version ''
        help_options_title help_option_device_name help_option_address help_option_user help_option_password
        help_option_port help_option_language help_option_use_oxidized help_option_oxidized_home
        help_option_use_identity_name help_option_backup_root help_option_use_net_folder
        help_option_monthly_archive help_option_log_level help_option_main_log_path
        help_option_backup_type help_option_export_format
        help_option_show_sensitive help_option_encrypt help_option_clear_dns_cache
        help_option_clear_console_history ''
        ''
    )
    (( ${#RolesOut[@]} == ${#KeysOut[@]} )) || return 80
    return 0
}

# Назначение: Локализует Help definition в массивы ролей/строк для renderer без ANSI-зависимости.
# shellcheck disable=SC2034,SC2178  # Semantic arrays are returned through namerefs.
build_cli_help_source()
{
    local -n RolesOut="$1"
    local -n LinesOut="$2"
    local Index=0
    local Text=''
    local -a HelpRoles=()
    local -a HelpKeys=()

    build_cli_help_definition HelpRoles HelpKeys || return $?
    RolesOut=("${HelpRoles[@]}")
    LinesOut=()
    for ((Index=0; Index<${#HelpKeys[@]}; Index++)); do
        if [[ "${HelpRoles[Index]}" == blank ]]; then
            LinesOut+=('')
            continue
        fi
        localized_message "${HelpKeys[Index]}" Text
        LinesOut+=("$Text")
    done
    return 0
}

# Назначение: Печатает Help в неинтерактивный stdout как простой текст без рамки и pager hints.
# shellcheck disable=SC2034  # HelpRoles is populated through the shared-source nameref.
render_cli_help_console()
{
    local -a HelpRoles=()
    local -a HelpLines=()

    build_cli_help_source HelpRoles HelpLines || return $?
    printf '%s\n' "${HelpLines[@]}"
    return 0
}

# Назначение: Собирает локализованный Usage Instruction в структурированный документ для UI.
# shellcheck disable=SC2034,SC2178  # Semantic arrays are returned through namerefs.
build_instruction_source()
{
    local -n RolesOut="$1"
    local -n LinesOut="$2"
    local Index=0
    local Key=''
    local Text=''
    local Role=text

    RolesOut=()
    LinesOut=()
    for ((Index=1; Index<=28; Index++)); do
        printf -v Key 'instruction_%02d' "$Index"
        localized_message "$Key" Text
        case "$Index" in
            1|2|10|16|22|25) Role=heading ;;
            15|18|21) Role=code ;;
            *) Role=text ;;
        esac
        RolesOut+=("$Role")
        LinesOut+=("$Text")
        case "$Index" in
            1|6|7|9|10|11|12|13|15|16|17|18|19|21|22|23|24|25|26|27)
                RolesOut+=(blank)
                LinesOut+=('')
                ;;
        esac
    done
    return 0
}

# Назначение: Открывает Help или Instruction через общий terminal document viewer.
# shellcheck disable=SC2034  # Document vectors and outcome are consumed through namerefs.
run_document_screen()
{
    local Kind="$1"
    local -n ExitRequestedOut="$2"
    local Title=''
    local HintsName=''
    local ReturnLabel=''
    local ExitLabel=''
    local Choice=0
    local Width="$UiWidth"
    local TitleRole=HelpTitle
    local LowerSeparator=true
    local -a Roles=()
    local -a Lines=()
    local -a Actions=()
    local -a ActionHints=()
    local -A Accelerators=([0]=0 [6]=1)

    ExitRequestedOut=false
    localized_message document_return ReturnLabel
    localized_message document_exit ExitLabel
    Actions=("$ReturnLabel" "$ExitLabel")
    if [[ "$Kind" == help ]]; then
        localized_message help_title Title
        localized_message help_return_hint ActionHints[0]
        localized_message help_exit_hint ActionHints[1]
        HintsName=ActionHints
        build_cli_help_source Roles Lines || return $?
    else
        localized_message instruction_title Title
        Width="$InstructionWidth"
        TitleRole=InstructionTitle
        LowerSeparator=false
        build_instruction_source Roles Lines || return $?
    fi
    ui_select "$Title" Actions 0 Choice '' '' document \
        Roles Lines "$Width" "$HintsName" "$TitleRole" "$LowerSeparator" \
        Accelerators || return $?
    (( Choice == 1 )) && ExitRequestedOut=true
    return 0
}

# ==============================================================================
# Main Menu
# ==============================================================================

# Назначение: В изолированной подоболочке пассивно проверяет наличие runnable-записи DeviceList, не изменяя состояние родителя и не импортируя источники.
passive_device_list_has_runnable_device()
(
    local Status=0

    ExecutionIntent[Kind]=batch_candidate
    construct_effective_config >/dev/null 2>&1 || exit 1
    validate_effective_config >/dev/null 2>&1 || exit 1
    load_canonical_device_list "${RuntimeState[DeviceListPath]}" canonical_tsv >/dev/null 2>&1 || Status=$?
    (( Status == 0 && ${SourceStats[Accepted]:-0} > 0 ))
)

# Назначение: Запускает configured batch из меню и возвращает его итог после единственного summary.
run_menu_batch_backup()
{
    local Status=0

    ExecutionIntent[Kind]=batch_candidate
    construct_effective_config || return $?
    run_configured_execution || Status=$?
    emit_backup_result_summary "$Status" || return 80
    return "$Status"
}

# Назначение: Поддерживает главное меню до явного выхода, корректно возвращаясь после неисполняющих действий Master.
# shellcheck disable=SC2034  # Accelerator metadata is consumed through the selector nameref.
run_persistent_menu()
{
    local Title=''
    local BackupLabel=''
    local BatchLabel=''
    local EditorLabel=''
    local HelpLabel=''
    local InstructionLabel=''
    local ExitLabel=''
    local Choice=0
    local Status=0
    local BatchAvailable=false
    local OptionPresent=false
    local ExitRequested=false
    local -a Items=()
    local -a Actions=()
    local -a Disabled=()
    local -a Descriptions=()
    local -A Accelerators=()

    while true; do
        localized_message menu_title Title
        localized_message menu_backup BackupLabel
        localized_message menu_batch BatchLabel
        if [[ "${RuntimeState[StartupConfigUsable]:-false}" == true ]]; then
            localized_message menu_editor_edit EditorLabel
            OptionPresent=true
        else
            localized_message menu_editor_create EditorLabel
            OptionPresent=false
        fi
        localized_message menu_help HelpLabel
        localized_message menu_instruction InstructionLabel
        localized_message menu_exit ExitLabel
        BatchAvailable=false
        passive_device_list_has_runnable_device && BatchAvailable=true

        Items=("$BackupLabel")
        Actions=(master)
        Descriptions=("${PresentationMessages[menu_backup_hint]}")
        Disabled=(false)
        Accelerators=([1]=0)
        if [[ "$BatchAvailable" == true ]]; then
            Accelerators[2]="${#Items[@]}"
            Items+=("$BatchLabel")
            Actions+=(batch)
            Descriptions+=("${PresentationMessages[menu_batch_hint]}")
            Disabled+=(false)
        fi
        Accelerators[3]="${#Items[@]}"
        Items+=("$EditorLabel")
        Actions+=(editor)
        if [[ "$OptionPresent" == true ]]; then
            Descriptions+=("${PresentationMessages[menu_editor_edit_hint]}")
        else
            Descriptions+=("${PresentationMessages[menu_editor_create_hint]}")
        fi
        Disabled+=(false)
        Accelerators[4]="${#Items[@]}"
        Items+=("$HelpLabel"); Actions+=(help); Descriptions+=("${PresentationMessages[menu_help_hint]}"); Disabled+=(false)
        Accelerators[5]="${#Items[@]}"
        Items+=("$InstructionLabel"); Actions+=(instruction); Descriptions+=("${PresentationMessages[menu_instruction_hint]}"); Disabled+=(false)
        Accelerators[6]="${#Items[@]}"
        Items+=("$ExitLabel"); Actions+=(exit); Descriptions+=("${PresentationMessages[menu_exit_hint]}"); Disabled+=(false)

        ui_select "$Title" Items 0 Choice '' Disabled main Descriptions \
            "$((${#Items[@]} - 1))" '' '' '' '' Accelerators || return $?
        case "${Actions[Choice]}" in
            master)
                Status=0
                run_backup_master || Status=$?
                if [[ "${RuntimeState[WizardExitRequested]:-false}" == true ]]; then
                    return "$Status"
                fi
                if [[ "${RuntimeState[WizardExecuted]:-false}" != true ]]; then
                    continue
                fi
                emit_backup_result_summary "$Status" || return 80
                return "$Status"
                ;;
            batch)
                run_menu_batch_backup
                return $?
                ;;
            editor) run_configuration_editor true || return $? ;;
            help)
                run_document_screen help ExitRequested || return $?
                [[ "$ExitRequested" == true ]] && return 0
                ;;
            instruction)
                run_document_screen instruction ExitRequested || return $?
                [[ "$ExitRequested" == true ]] && return 0
                ;;
            exit) return 0 ;;
        esac
    done
}

# ==============================================================================
# Top-level action/configured-run orchestration, compatibility seam and entry point
# ==============================================================================

# Назначение: Маршрутизирует выбранные CLI help/instruction/editor/master/menu действия к соответствующим terminal surfaces.
dispatch_terminal_action()
{
    case "${ExecutionIntent[Action]}" in
        help)
            render_cli_help_console
            return $?
            ;;
        version)
            local VersionText
            localized_message version VersionText
            printf '%s %s\n' "$VersionText" "$ProgramVersion"
            return 0
            ;;
        editor)
            run_configuration_editor false
            return $?
            ;;
        restore|auxiliary)
            emit_message not_implemented
            return 80
            ;;
    esac
    return 80
}

# Назначение: Сохраняет совместимую с TASK-001 заглушку: всегда возвращает 80, ничего не запускает и не вызывается основным потоком программы.
dispatch_foundation_stub()
{
    # Compatibility seam for the accepted TASK-001 foundation boundary. The
    # production main flow no longer calls this stub.
    return 80
}

# Назначение: Выполняет полную headless-последовательность config, source, storage, dependencies и backup pipeline.
run_configured_execution()
{
    local Status=0

    validate_effective_config || Status=$?
    if (( Status != 0 )); then
        promote_run_result "$Status"
        emit_runtime_log_event shell script context error '' \
            result_invocation_failure "$Status" error '' none \
            none '' '' '' '' primary || :
        flush_runtime_log_events fallback || :
        return "${RuntimeState[RunResult]}"
    fi
    LoggingState[TerminalContext]=shell

    Status=0
    validate_mikrotik_driver_contract || Status=$?
    if (( Status != 0 )); then
        promote_run_result "$Status"
        emit_runtime_log_event shell script context error '' \
            driver_contract_failure "$Status" error '' none \
            none '' '' '' '' primary || :
        emit_message driver_contract_failure
        flush_runtime_log_events effective || :
        return "${RuntimeState[RunResult]}"
    fi

    Status=0
    resolve_run_mode '' || Status=$?
    if (( Status != 0 )); then
        promote_run_result "$Status"
        emit_runtime_log_event shell script context error '' no_device_source \
            "$Status" error '' none none '' '' '' '' primary || :
        emit_message no_device_source
        flush_runtime_log_events effective || :
        return "${RuntimeState[RunResult]}"
    fi

    if [[ "${ExecutionState[RunMode]}" == menu ]]; then
        Status=0
        run_terminal_ui run_persistent_menu || Status=$?
        promote_run_result "$Status"
        flush_runtime_log_events effective || :
        return "${RuntimeState[RunResult]}"
    fi

    Status=0
    capture_monthly_archive_context || Status=$?
    if (( Status != 0 )); then
        promote_run_result "$Status"
        emit_runtime_log_event shell script context error '' \
            result_internal_failure "$Status" error '' none \
            none '' '' '' '' primary || :
        flush_runtime_log_events effective || :
        return "${RuntimeState[RunResult]}"
    fi

    Status=0
    check_naming_locale_capability || Status=$?
    if (( Status != 0 )); then
        promote_run_result "$Status"
        emit_runtime_log_event shell script context error '' \
            naming_locale_unavailable "$Status" error '' none \
            none '' '' '' '' primary || :
        emit_message naming_locale_unavailable
        flush_runtime_log_events effective || :
        return "${RuntimeState[RunResult]}"
    fi

    if [[ "${ExecutionState[RunMode]}" == batch ]]; then
        Status=0
        prepare_device_source || Status=$?
        if (( Status != 0 )); then
            promote_run_result "$Status"
            emit_message source_failure
            flush_runtime_log_events effective || :
            return "${RuntimeState[RunResult]}"
        fi
        Status=0
        emit_runtime_log_event shell script main short '' \
            log_device_list_loading '' start '' none \
            none '' '' '' '' primary || :
        load_device_collection || Status=$?
        if (( Status != 0 )); then
            promote_run_result "$Status"
            emit_runtime_log_event shell script main short '' \
                log_device_list_loading "$Status" outcome '' none \
                none '' '' '' '' primary || :
            emit_message source_failure
            flush_runtime_log_events effective || :
            return "${RuntimeState[RunResult]}"
        fi
        emit_source_summary
        if (( ${#DeviceIds[@]} == 0 )); then
            promote_run_result 22
            emit_runtime_log_event shell script main short '' \
                log_device_list_loading 22 outcome '' none \
                none '' '' '' '' primary || :
            emit_message missing_device_list
            flush_runtime_log_events effective || :
            return "${RuntimeState[RunResult]}"
        fi
        emit_runtime_log_event shell script main short '' log_device_list_loaded \
            0 outcome '' none source_stats "${SourceStats[Read]}" \
            "${SourceStats[Accepted]}" "${SourceStats[Filtered]}" \
            "${SourceStats[Skipped]}" primary || :
    fi

    build_dependency_profile
    Status=0
    check_dependencies || Status=$?
    if (( Status != 0 )); then
        promote_run_result "$Status"
        emit_runtime_log_event shell script context error '' missing_dependency \
            "$Status" error '' none none '' '' '' '' primary || :
        emit_message missing_dependency
        flush_runtime_log_events effective || :
        return "${RuntimeState[RunResult]}"
    fi

    Status=0
    check_transport_client_capabilities || Status=$?
    if (( Status != 0 )); then
        promote_run_result "$Status"
        emit_runtime_log_event shell script context error '' \
            transport_capability_failure "$Status" error '' none \
            none '' '' '' '' primary || :
        emit_message transport_capability_failure
        flush_runtime_log_events effective || :
        return "${RuntimeState[RunResult]}"
    fi

    Status=0
    prepare_storage_and_root_lock || Status=$?
    if (( Status != 0 )); then
        promote_run_result "$Status"
        emit_runtime_log_event shell script context error '' storage_failure \
            "$Status" error '' none none '' '' '' '' primary || :
        emit_message storage_failure
        flush_runtime_log_events effective || :
        return "${RuntimeState[RunResult]}"
    fi
    flush_runtime_log_events effective || :

    Status=0
    dispatch_backup_pipeline || Status=$?
    promote_run_result "$Status"
    return "${RuntimeState[RunResult]}"
}

# Назначение: Координирует bootstrap, traps, CLI, presentation и единственное выбранное действие, затем возвращает накопленный run result.
main()
{
    local Status=0

    check_bash_version "${BASH_VERSINFO[0]:-0}" "${BASH_VERSINFO[1]:-0}" || exit $?
    bootstrap_runtime || exit $?
    install_runtime_traps
    init_builtin_localization
    init_default_values
    init_mikrotik_driver
    Status=0
    parse_cli "$@" || Status=$?
    if (( Status != 0 )); then
        resolve_presentation_language 2>/dev/null || :
        promote_run_result "$Status"
        emit_message invalid_cli
        exit "${RuntimeState[RunResult]}"
    fi

    Status=0
    validate_action_selection || Status=$?
    if (( Status != 0 )); then
        resolve_presentation_language 2>/dev/null || :
        promote_run_result "$Status"
        emit_message action_conflict
        exit "${RuntimeState[RunResult]}"
    fi

    determine_execution_intent

    Status=0
    load_startup_option_config || Status=$?
    if (( Status != 0 )); then
        promote_run_result "$Status"
        exit "${RuntimeState[RunResult]}"
    fi

    Status=0
    resolve_presentation_language || Status=$?
    if (( Status != 0 )); then
        promote_run_result "$Status"
        exit "${RuntimeState[RunResult]}"
    fi

    if [[ "${ExecutionIntent[Kind]}" == terminal_action ]]; then
        Status=0
        if [[ "${ExecutionIntent[Action]}" == editor ]]; then
            run_terminal_ui dispatch_terminal_action || Status=$?
        else
            dispatch_terminal_action || Status=$?
        fi
        promote_run_result "$Status"
        exit "${RuntimeState[RunResult]}"
    fi
    if [[ "${ExecutionIntent[Kind]}" == partial_single ]]; then
        promote_run_result 12
        emit_partial_single_diagnostic
        exit "${RuntimeState[RunResult]}"
    fi
    if [[ "${ExecutionIntent[Kind]}" == batch_candidate &&
          "${RuntimeState[StartupConfigUsable]:-false}" != true ]]; then
        Status=0
        run_terminal_ui run_configuration_editor false || Status=$?
        promote_run_result "$Status"
        exit "${RuntimeState[RunResult]}"
    fi
    if [[ "${ExecutionIntent[Kind]}" == menu || "${ExecutionIntent[Kind]}" == wizard ]]; then
        Status=0
        if [[ "${ExecutionIntent[Kind]}" == menu ]]; then
            run_terminal_ui run_persistent_menu || Status=$?
        else
            run_standalone_backup_master || Status=$?
        fi
        promote_run_result "$Status"
        exit "${RuntimeState[RunResult]}"
    fi

    Status=0
    construct_effective_config || Status=$?
    if (( Status != 0 )); then
        promote_run_result "$Status"
        exit "${RuntimeState[RunResult]}"
    fi

    Status=0
    run_configured_execution || Status=$?
    promote_run_result "$Status"
    exit "${RuntimeState[RunResult]}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
