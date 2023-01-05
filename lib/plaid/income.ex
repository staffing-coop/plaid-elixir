defmodule Plaid.Income do
  @moduledoc """
  Functions for Plaid `income` endpoint.
  """

  alias Plaid.Client.Request
  alias Plaid.Client

  @derive Jason.Encoder
  defstruct item: nil, income: nil, request_id: nil

  @type t :: %__MODULE__{
          item: Plaid.Item.t(),
          income: Plaid.Income.Income.t(),
          request_id: String.t()
        }
  @type params :: %{required(atom) => term}
  @type config :: %{required(atom) => String.t() | keyword}
  @type error :: {:error, Plaid.Error.t() | any()} | no_return

  defmodule Income do
    @moduledoc """
    Plaid.Income Income data structure.
    """

    @derive Jason.Encoder
    defstruct income_streams: [],
              last_year_income: nil,
              last_year_income_before_tax: nil,
              projected_yearly_income: nil,
              projected_yearly_income_before_tax: nil,
              max_number_of_overlapping_income_streams: nil,
              number_of_income_streams: nil

    @type t :: %__MODULE__{
            income_streams: [Plaid.Income.Income.IncomeStream.t()],
            last_year_income: float(),
            last_year_income_before_tax: float(),
            projected_yearly_income: float(),
            projected_yearly_income_before_tax: float(),
            max_number_of_overlapping_income_streams: float(),
            number_of_income_streams: float()
          }

    defmodule IncomeStream do
      @moduledoc """
      Plaid.Income.Income IncomeStream data structure.
      """

      @derive Jason.Encoder
      defstruct confidence: nil, days: nil, monthly_income: nil, name: nil

      @type t :: %__MODULE__{
              confidence: float(),
              days: integer(),
              monthly_income: float(),
              name: String.t()
            }
    end

    defmodule CreditSession do

      @derive Jason.Encoder
      defstruct link_session_id: nil, session_start_time: nil, results: %{}

      @type t :: %__MODULE__{
        link_session_id: String.t(),
        session_start_time: String.t(), # TODO assess if this should be type DateTime
        results: Plaid.Income.Income.CreditSession.Results.t()
        # results: %{
        #   # FIXME this is not the right module structure
        #   bank_income_results: [Plaid.Income.Income.CreditSessionBankIncomeResult.t()],
        #   item_add_results: [Plaid.Income.Income.CreditSessionItemAddResult.t()],
        #   payroll_income_results: [Plaid.Income.Income.CreditSessionPayrollIncomeResult.t()],
        # }
      }
      defmodule PayrollIncomeResult do
        @derive Jason.Encoder
        defstruct num_paystubs_retrieved: nil, num_w2s_retrieved: nil, institution_id: nil

        @type t :: %__MODULE__{
          num_paystubs_retrieved: Integer.t(),
          num_w2s_retrieved: Integer.t(),
          institution_id: String.t()
        }
      end

      defmodule ItemAddResult do
        @derive Jason.Encoder
        defstruct public_token: nil, item_id: nil, institution_id: nil

        @type t :: %__MODULE__{
          public_token: String.t(),
          item_id: String.t(),
          institution_id: String.t()
        }
      end

      defmodule BankIncomeResult do
        @derive Jason.Encoder
        defstruct status: nil, item_id: nil, institution_id: nil

        @type t :: %__MODULE__{
          status: String.t(),
          item_id: String.t(),
          institution_id: String.t()
        }
      end

      defmodule Results do
        @derive Jason.Encoder
        defstruct bank_income_results: [], item_add_results: [], payroll_income_results: []

        @type t :: %__MODULE__{
          bank_income_results: [Plaid.Income.Income.CreditSession.BankIncomeResult.t()],
          payroll_income_results: [Plaid.Income.Income.CreditSession.PayrollIncomeResult.t()],
          item_add_results: [Plaid.Income.Income.CreditSession.ItemAddResult.t()],
        }
      end

    # defmodule CreditSession do
    end

    defmodule CreditSessions do
      @derive Jason.Encoder
      defstruct request_id: nil, sessions: []

      @type t :: %__MODULE__{
        request_id: String.t(),
        sessions: [Plaid.Income.Income.CreditSession.t()]
      }
    end
  end

  @doc """
  Gets Income data associated with an Access Token.

  Parameters
  ```
  %{
    access_token: "access-env-identifier"
  }
  ```
  """
  @spec get(params, config) :: {:ok, Plaid.Income.t()} | error
  def get(params, config \\ %{}) do
    c = config[:client] || Plaid

    Request
    |> struct(method: :post, endpoint: "income/get", body: params)
    |> Request.add_metadata(config)
    |> c.send_request(Client.new(config))
    |> c.handle_response(&map_income(&1))
  end

  def get_credit_sessions(params, config \\ %{}) do
    c = config[:client] || Plaid

    Request
    |> struct(method: :post, endpoint: "credit/sessions/get", body: params)
    |> Request.add_metadata(config)
    |> c.send_request(Client.new(config))
    |> c.handle_response(&map_credit_session(&1))
  end

  def get_bank_income(params, config \\ %{}) do
    c = config[:client] || Plaid

    Request
    |> struct(method: :post, endpoint: "income/get", body: params)
    |> Request.add_metadata(config)
    |> c.send_request(Client.new(config))
    |> c.handle_response(&map_income(&1))
  end

  defp map_income(body) do
    Poison.Decode.transform(
      body,
      %{
        as: %Plaid.Income{
          item: %Plaid.Item{},
          income: %Plaid.Income.Income{
            income_streams: [
              %Plaid.Income.Income.IncomeStream{}
            ]
          }
        }
      }
    )
  end

  defp map_credit_session(body) do
    Poison.Decode.transform(
      body,
      %{
        as: %Plaid.Income.Income.CreditSessions{
          # item: %Plaid.Item{},
          sessions: [
            %Plaid.Income.Income.CreditSession{
              results: %Plaid.Income.Income.CreditSession.Results{
                bank_income_results: [%Plaid.Income.Income.CreditSession.BankIncomeResult{}],
                payroll_income_results: [%Plaid.Income.Income.CreditSession.PayrollIncomeResult{}],
                item_add_results: [%Plaid.Income.Income.CreditSession.ItemAddResult{}]
              }
            }
          ]
        }
      }
    )
  end
end
