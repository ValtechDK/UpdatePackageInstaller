<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="log4net" %>
<%@ Import Namespace="Sitecore" %>
<%@ Import Namespace="Sitecore.ContentSearch" %>
<%@ Import Namespace="Sitecore.Data.Engines" %>
<%@ Import Namespace="Sitecore.Data.Proxies" %>
<%@ Import Namespace="Sitecore.Diagnostics" %>
<%@ Import Namespace="Sitecore.Jobs" %>
<%@ Import Namespace="Sitecore.Search" %>
<%@ Import Namespace="Sitecore.SecurityModel" %>
<%@ Import Namespace="Sitecore.Update" %>
<%@ Import Namespace="Sitecore.Update.Installer" %>
<%@ Import Namespace="Sitecore.Update.Installer.Exceptions" %>
<%@ Import Namespace="Sitecore.Data.Managers" %>
<%@ Import Namespace="Sitecore.Data" %>
<%@ Import Namespace="Sitecore.Publishing" %>

<%@  Language="C#" %>
<script runat="server" language="C#">
	private Handle handle = null;
	private string msg = string.Empty;
	List<string> messages = new List<string>(); 
	public void Page_Load(object sender, EventArgs e)
	{
		Sitecore.Context.SetActiveSite("shell");
		using (new SecurityDisabler())
		{
			DateTime publishDate = DateTime.Now;
			Sitecore.Data.Database master = Sitecore.Configuration.Factory.GetDatabase("master");
			Sitecore.Data.Database web = Sitecore.Configuration.Factory.GetDatabase("web");
			Log.Info("Deployment: starting Smart publish", new object());
			handle = PublishManager.PublishSmart(Client.ContentDatabase, new Database[] { web }, LanguageManager.GetLanguages(master).ToArray(), Sitecore.Context.Language);
			var status = GetStatus();
			Log.Info("Deployment: publish status: " + status, new object());
			if (status)
			{
				msg = "Deployment: publish status: " + status + Environment.NewLine;
				msg += RebuildIndexes();
			}
			else
			{
				msg = "Deployment: Error publishing database " + Environment.NewLine;
			}
		}
		Response.Write(msg);
	}

	protected string RebuildIndexes()
	{
		var indexes = ContentSearchManager.Indexes.ToList();

		var resultMessage = "";
		Log.Info("Deployment: " + indexes.Count + " indexes found (" + string.Join(", ", indexes.Select(t => t.Name)) + ")", this);
		resultMessage += "Deployment: " + indexes.Count + " indexes found (" + string.Join(", ", indexes.Select(t => t.Name)) + ")" + Environment.NewLine;
		using (new SecurityDisabler())
		{
			foreach (var index in indexes)
			{
				Log.Info("Deployment: Start rebuilding " + index.Name, this);
				resultMessage += "Deployment: Start rebuilding " + index.Name + Environment.NewLine;
				try
				{
					index.Rebuild();
				}
				catch (Exception ex)
				{
					Log.Error("Deployment: Error rebuilding " + index.Name + ". Message: " + ex.Message, ex, this);
					resultMessage += "Deployment: Error rebuilding " + index.Name + ". Message: " + ex.Message + Environment.NewLine;
				}
				Log.Info("Deployment: End rebuilding " + index.Name, this);
				resultMessage += "Deployment: End rebuilding " + index.Name + Environment.NewLine;
			}
		}
		return resultMessage;
	}

	protected bool GetStatus()
	{
		if (IsPublishing())
		{
			Thread.Sleep(2000);
			return GetStatus();
		}
		return true;
	}

	protected bool IsPublishing()
	{
		var result = false;
		var jobs = Sitecore.Jobs.JobManager.GetJobs();
		foreach (var job in jobs)
		{
			if (job.IsDone)
			{
				continue;
			}
			if (job.Name == "Publish")
			{
				if (job.Options != null && job.Options.Parameters != null)
				{
					foreach (var par in job.Options.Parameters)
					{
						if (par.GetType() == typeof(PublishStatus))
						{
							var ps = (PublishStatus)par;
							Log.Info("Deployment: Found Publish: " + string.Format(" CurrentLanguage:{0} CurrentTarget:{1}", ps.CurrentLanguage == null ? "Unknown" : ps.CurrentLanguage.ToString(), ps.CurrentTarget), new object());
							result = true;
						}
					}
				}
			}
			else if (job.Name.StartsWith("Publish"))
			{
				Log.Info("Deployment: Found Publish: Processed=" + job.Status.Processed, new object());
				result = true;
			}
		}
		return result;
	}

	protected String GetTime()
	{
		return DateTime.Now.ToString("t");
	}
   
</script>
