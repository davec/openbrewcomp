xml.OrgReport do
  xml.CompData do
    xml.CompID(@competition_data[:id])
    xml.CompName(@competition_data[:name])
    xml.CompDate(@competition_data[:date].to_s(:db))
    xml.CompEntries(@competition_data[:entries])
    xml.CompDays(@competition_data[:days])
    xml.CompSessions(@competition_data[:sessions])
    xml.CompFlights(@competition_data[:flights])
  end
  xml.BJCPpoints do
    @bjcp_judges.each do |judge|
      xml.JudgeData do
        staff_points = judge.staff_points || 0
        xml.JudgeID(judge.judge_number)
        xml.JudgeName(judge.name)
        xml.JudgeRole(judge.role)
        xml.JudgePts(judge.judge_points)
        xml.NonJudgePts(judge.organizer? ? PointAllocation.organizer_points : (staff_points + judge.steward_points))
      end
    end
  end
  xml.NonBJCP do
    @non_bjcp_judges.each do |judge|
      xml.JudgeData do
        staff_points = judge.staff_points || 0
        xml.JudgeName(judge.name)
        xml.JudgeRole(judge.role)
        xml.JudgePts(judge.judge_points)
        xml.NonJudgePts(judge.organizer? ? PointAllocation.organizer_points : (staff_points + judge.steward_points))
      end
    end
  end
  xml.Comments(@comments)
  xml.IPAddress(request.remote_ip)
  xml.SubmissionDate(Time.now.strftime("%a, %d %B %Y %I:%M %P"))
end
