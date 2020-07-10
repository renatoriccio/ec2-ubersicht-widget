command: "query=\"Reservations[*].Instances[].{InstanceId:InstanceId,ImageId:ImageId,InstanceType:InstanceType,LaunchTime:LaunchTime,AZ:Placement.AvailabilityZone,State:State.Name,IP:PublicIpAddress,Name:Tags[?Key=='Name'].Value[]}\";

source ec2.widget/config

obj1=[];
obj2=[];

REGIONS=$( /usr/local/bin/aws ec2 describe-regions --cli-connect-timeout 3 --output text --query 'Regions[].{Name:RegionName}' 2>/dev/null );

if [ $? -ne 0 ]; then
  echo '[{\"error\": \"Unable to reach AWS API\"}]';
  exit;
fi;

REGIONS_LIST=`echo \"$REGIONS\" | grep 'eu\\|ap'`;

while read region; \
do
  obj1_tmp=`/usr/local/bin/aws ec2 describe-instances \
  --filters Name=key-name,Values=$NAME \
  --query  $query \
  --output json --region $region \
  --cli-connect-timeout 3`; \

  obj1=$(echo $obj1 $obj1_tmp | /usr/local/bin/jq -s add);

  obj2_tmp=`/usr/local/bin/aws ec2 describe-instances \
  --filters Name=tag:owner,Values=$OWNER \
  --query $query \
  --output json --region $region \
  --cli-connect-timeout 3`; \

  obj2=$(echo $obj2 $obj2_tmp | /usr/local/bin/jq -s add);

done <<< \"$(echo \"$REGIONS_LIST\")\";

echo $obj1 $obj2 | \
/usr/local/bin/jq -s add | /usr/local/bin/jq 'unique_by(.InstanceId)';
"


refreshFrequency: 300000 # 5 minutes

style: """
  // Change the style of the widget
  color #fff
  font-family Helvetica Neue
  background rgba(#000, .5)
  padding 10px 10px 5px
  border-radius 5px

  left: 20px
  top: 500px
  min-width: 150px
  max-width: 900px
  table    width: 100%
    text-align: right
  table thead tr th
    border-bottom: 1px dashed white
    opacity: 0.5
  table tbody tr:first-child td
  table th:first-child, table td:first-child
    text-align left
  .message
    opacity: 0.5
    text-align: right
  a
    color: white
    text-decoration: none
  td,th
    font-size: 10px
    font-weight: 300
    color: rgba(#fff, .9)
    text-shadow: 0 1px 0px rgba(#000, .7)
  h1
    font-size 12px
    text-transform uppercase
    font-weight bold
  .stop, .shell, .terminate
    cursor: pointer
    padding: 2px 4px
    border: none
    border-radius: 5px
    background-color: rgba(255, 255, 255, 0.8)
"""

render: -> """
  <h1>Running EC2 instances  <button class="refresh">refresh</button></h1>
  <table></table>
  <p class='message'></p>
"""

update: (output, domEl) ->
  @$domEl = $(domEl)
  @renderTable output

renderTable: (data) ->
  $table = @$domEl.find('table')

  $table.html("""<thead>
               <tr>
                 <th>AZ</th>
                 <th>IP</th>
                 <th>InstanceType</th>
                 <th>Name</th>
                 <th>State</th>
                 <th>Action</th>
               </tr>
              </thead>
              <tbody></tbody>
              <tfooter></tfooter>
  """)
  $tableBody = $table.find('tbody')

  for key, value of JSON.parse data
      $tableBody.append @renderRow(key, value)

afterRender: (domEl) ->

 $(domEl).on 'click', '.stop', (e) =>
  target = $(e.currentTarget)
  image = $(target).attr 'instance-id'
  region = $(target).attr 'region'
  region = region.replace(/(.*-.*-[1-9]).*/, '$1')
  @run "/usr/local/bin/aws ec2 stop-instances --instance-ids " + image + " --region " + region
  this.refresh()

 $(domEl).on 'click', '.start', (e) =>
  target = $(e.currentTarget)
  image = $(target).attr 'instance-id'
  region = $(target).attr 'region'
  region = region.replace(/(.*-.*-[1-9]).*/, '$1')
  @run "/usr/local/bin/aws ec2 start-instances --instance-ids " + image + " --region " + region
  this.refresh()

 $(domEl).on 'click', '.shell', (e) =>
  target = $(e.currentTarget)
  image = $(target).attr 'instance-id'
  region = $(target).attr 'region'
  region = region.replace(/(.*-.*-[1-9]).*/, '$1')
  @run "ec2.widget/helper.sh shell " + image + " " + region
  this.refresh()

 $(domEl).on 'click', '.terminate', (e) =>
  target = $(e.currentTarget)
  image = $(target).attr 'instance-id'
  region = $(target).attr 'region'
  region = region.replace(/(.*-.*-[1-9]).*/, '$1')
  state = $(target).attr 'state'
  @run "/usr/local/bin/aws ec2 terminate-instances --instance-ids " + image + " --region " + region
  this.refresh()

 $(domEl).on 'click', '.refresh', (e) =>
  this.refresh()

renderRow: (key, value) ->
  isArray = Array.isArray or (obj) -> toString.call(obj) == '[object Array]'
  if value.error?
    return """<tr>
              <td>#{value.error}</td>
            </tr>"""
  name = if isArray value.Name then value.Name[0] else ""
  return """<tr>
              <td>#{value.AZ}</td>
              <td>#{value.IP}</td>
              <td>#{value.InstanceType}</td>
              <td>#{name}</a></td>
              <td>#{value.LaunchTime}</td>
              <td>#{value.State}</td>
              <td>
                <button instance-id="#{ value.InstanceId }" region="#{ value.AZ }" state="#{value.State}" class="terminate">terminate</button>
                <button instance-id="#{ value.InstanceId }" region="#{ value.AZ }" state="#{value.State}" class="stop">stop</button>
                <button instance-id="#{ value.InstanceId }" region="#{ value.AZ }" state="#{value.State}" class="start">start</button>
                <button instance-id="#{ value.InstanceId }" region="#{ value.AZ }" state="#{value.State}" class="shell">shell</button>
              </td>
 state=""            </tr>"""
