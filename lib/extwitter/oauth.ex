defmodule ExTwitter.OAuth do
  @moduledoc """
  Provide a wrapper for `:oauth` request methods.
  """

  @doc """
  Send request with get/post method.
  """
  def request(:get, url, params, consumer_key, consumer_secret, access_token, access_token_secret) do
    oauth_get(url, params, consumer_key, consumer_secret, access_token, access_token_secret, [])
  end

  def request(:post, url, params, consumer_key, consumer_secret, access_token, access_token_secret) do
    oauth_post(url, params, consumer_key, consumer_secret, access_token, access_token_secret, [])
  end

  @doc """
  Send async request with get or post method.
  """
  def request_async(:get, url, params, consumer_key, consumer_secret, access_token, access_token_secret) do
    oauth_get(url, params, consumer_key, consumer_secret, access_token, access_token_secret, stream_option())
  end

  def request_async(:post, url, params, consumer_key, consumer_secret, access_token, access_token_secret) do
    oauth_post(url, params, consumer_key, consumer_secret, access_token, access_token_secret, stream_option())
  end

  @doc """
  Send oauth request with get or post method.
  """
  def oauth_get(url, params, consumer_key, consumer_secret, access_token, access_token_secret, options) do
    signed_params = get_signed_params(
      "get", url, params, consumer_key, consumer_secret, access_token, access_token_secret)
    {header, req_params} = OAuther.header(signed_params)

    header = header |> Tuple.to_list() |> Enum.map(&to_charlist/1) |> List.to_tuple()
    #request = {to_charlist(url <> "?" <> URI.encode_query(req_params)), [header]}
    #send_httpc_request(:get, request, options)
    full_url = url <> "?" <> URI.encode_query(req_params)
    send_hackney_request(:get, full_url, [header], [], options)
  end

  def oauth_post(url, params, consumer_key, consumer_secret, access_token, access_token_secret, options) do
    signed_params = get_signed_params(
      "post", url, params, consumer_key, consumer_secret, access_token, access_token_secret)
    encoded_params = URI.encode_query(signed_params)
    # request = {to_charlist(url), [], 'application/x-www-form-urlencoded', encoded_params}

    # send_httpc_request(:post, request, options)
    full_url = url <> "?" <> URI.encode_query(params)
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
    send_hackney_request(:post, full_url, headers, encoded_params, options)
  end

  def send_httpc_request(method, request, options) do
    :httpc.request(method, request, [{:autoredirect, false}] ++ proxy_option(), options)
  end

  defp send_hackney_request(method, url, headers, payload, options) do
    options = [{:autoredirect, false}, {:with_body, true}] ++ proxy_option() ++ options
    :hackney.request(method, url, headers, payload, options)
    |> case do
      {:ok, status_code, headers, body} -> {:ok, {status_code, headers, body}}
      other -> other
    end
  end

  defp get_signed_params(method, url, params, consumer_key, consumer_secret, access_token, access_token_secret) do
    credentials = OAuther.credentials(
        consumer_key: consumer_key,
        consumer_secret: consumer_secret,
        token: access_token,
        token_secret: access_token_secret
    )
    OAuther.sign(method, url, params, credentials)
  end

  defp stream_option do
    [{:sync, false}, {:stream, :self}]
  end

  defp proxy_option do
    ExTwitter.Proxy.options
  end
end
