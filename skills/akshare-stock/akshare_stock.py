import akshare as ak

def stock_info(symbol):
    """查询个股实时行情"""
    try:
        data = ak.stock_zh_a_spot_em(symbol=symbol)
        return data
    except Exception as e:
        return f"Error: {e}"

def stock_history(symbol, start_date, end_date, period="daily"):
    """查询历史 K 线"""
    try:
        data = ak.stock_zh_a_hist(
            symbol=symbol,
            period=period,
            start_date=start_date,
            end_date=end_date,
            adjust="qfq"
        )
        return data
    except Exception as e:
        return f"Error: {e}"

def stock_fund_flow(symbol, market="sh"):
    """查询资金流向"""
    try:
        data = ak.stock_individual_fund_flow(stock=symbol, market=market)
        return data
    except Exception as e:
        return f"Error: {e}"

def stock_board_industry():
    """查询行业板块"""
    try:
        data = ak.stock_board_industry_name_em()
        return data
    except Exception as e:
        return f"Error: {e}"

def stock_lhb(date=None):
    """查询龙虎榜"""
    try:
        import datetime
        if not date:
            date = datetime.datetime.now().strftime("%Y%m%d")
        data = ak.stock_lhb_detail_em(date=date)
        return data
    except Exception as e:
        return f"Error: {e}"
