package zuffy.display.fileList 
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class PageNavigator extends Sprite 
	{
		private var _totalNum:uint;
		private var _pagePerNum:uint;
		private var _totalPage:uint;
		private var _showItemNum:uint = 7;
		private var _currentPageNum:uint;
		private var _labelArray:Array;
		
		public function PageNavigator() 
		{
			
		}
		
		public function setOuterParam(totalNum:uint, totalPage:uint, pagePerNum:uint):void
		{
			_totalNum = totalNum;
			_totalPage = totalPage;
			_pagePerNum = pagePerNum;
			
			_labelArray = [];
			var i:uint;
			var label:String;
			var startIdx:uint;
			var endIdx:uint;
			var remindNum:uint = _totalNum - (_totalPage - 1) * _pagePerNum;
			for (i = 0; i < _totalPage; i++)
			{
				startIdx = i * _pagePerNum + 1;
				if (i == _totalPage - 1)
				{
					endIdx = i * _pagePerNum + remindNum;
				}
				else
				{
					endIdx = i * _pagePerNum + _pagePerNum;
				}
				label = startIdx + "-" + endIdx;
				
				_labelArray.push(label);
			}
		}
		
		public function set showItemNum(num:Number):void
		{
			_showItemNum = num;
		}
		
		private function update():void
		{
			var removeItem:PageNavItem;
			while (this.numChildren)
			{
				removeItem = this.removeChildAt(0) as PageNavItem;
				removeItem = null;
			}
			
			//除去开头和结尾，计算中间点，索引从0开始
			var midIdx:uint = Math.floor((_showItemNum - 2) / 2);
			//开始点索引，索引从0开始
			var startIdx:uint = Math.max(1, _currentPageNum - midIdx);
			//开始点最大索引，索引从0开始
			var maxStartIdx:uint = Math.max(1, (_totalPage - 1) - (_showItemNum - 2));
			startIdx = Math.min(startIdx, maxStartIdx);
			//var endIdx:uint = Math.min(startIdx + _showItemNum - 2, _totalPage - 2);
			
			var minLen:uint = Math.min(_showItemNum, _labelArray.length);
			var j:uint;
			var item:PageNavItem;
			var dotItem:PageNavItem;
			var spaceItem:PageNavItem;
			var lastX:Number = 0;
			var space:uint = 0;
			var itemWidth:uint = 55;
			var spaceWidth:uint = 5;
			for (j = 0; j < minLen; j++)
			{
				item = new PageNavItem(itemWidth);
				if (j == 0)
				{
					//第一项显示第一页
					item.pageNum = j;
					item.setLabel(_labelArray[j]);
					item.enabled = true;
					item.x = lastX;
					
					lastX = item.x + item.width + space;
					//lastX = item.x + itemWidth / 2 + 10;
					
					if (_labelArray.length > 1)
					{
						spaceItem = new PageNavItem(spaceWidth);
						spaceItem.x = lastX;
						spaceItem.setLabel("|");
						addChild(spaceItem);
						
						lastX = spaceItem.x + spaceItem.width + space;
						//lastX = item.x + itemWidth;
					}
				}
				else if (j == minLen - 1)
				{
					//最后一项显示最后一页
					item.pageNum = _totalPage - 1;
					item.setLabel(_labelArray[_totalPage - 1]);
					item.enabled = true;
					item.x = lastX;
					
					lastX = item.x + item.width + space;
					//lastX = item.x + itemWidth;
				}
				else
				{
					item.pageNum = startIdx + j - 1;
					item.setLabel(_labelArray[startIdx + j - 1]);
					item.enabled = true;
					
					if (j == 1 && startIdx > 1)
					{
						//第二项页数大于1时，显示...
						dotItem = new PageNavItem(itemWidth);
						dotItem.x = lastX;
						dotItem.setLabel("......");
						addChild(dotItem);
						
						lastX = dotItem.x + dotItem.width + space;
						//lastX = dotItem.x + itemWidth / 2 + 10;
						
						spaceItem = new PageNavItem(spaceWidth);
						spaceItem.x = lastX;
						spaceItem.setLabel("|");
						addChild(spaceItem);
						
						lastX = spaceItem.x + spaceItem.width + space;
						//lastX = dotItem.x + itemWidth;
						
						item.x = lastX;
						
						lastX = item.x + item.width + space;
						//lastX = item.x + itemWidth / 2 + 10;
						
						spaceItem = new PageNavItem(spaceWidth);
						spaceItem.x = lastX;
						spaceItem.setLabel("|");
						addChild(spaceItem);
						
						lastX = spaceItem.x + spaceItem.width + space;
						//lastX = item.x + itemWidth;
					}
					else if (j == minLen - 2 && startIdx + minLen - 2 - 1 < _totalPage - 2)
					{
						//倒数第二项页数小于_totalPage - 2时，显示...
						item.x = lastX;
						
						lastX = item.x + item.width + space;
						//lastX = item.x + itemWidth / 2 + 10;
						
						spaceItem = new PageNavItem(spaceWidth);
						spaceItem.x = lastX;
						spaceItem.setLabel("|");
						addChild(spaceItem);
						
						lastX = spaceItem.x + spaceItem.width + space;
						//lastX = item.x + itemWidth;
						
						dotItem = new PageNavItem(itemWidth);
						dotItem.x = lastX;
						dotItem.setLabel("......");
						addChild(dotItem);
						
						lastX = dotItem.x + dotItem.width + space;
						//lastX = dotItem.x + itemWidth / 2 + 10;
						
						spaceItem = new PageNavItem(spaceWidth);
						spaceItem.x = lastX;
						spaceItem.setLabel("|");
						addChild(spaceItem);
						
						lastX = spaceItem.x + spaceItem.width + space;
						//lastX = item.x + itemWidth;
					}
					else
					{
						item.x = lastX;
						
						lastX = item.x + item.width + space;
						//lastX = item.x + itemWidth / 2 + 10;
						
						spaceItem = new PageNavItem(spaceWidth);
						spaceItem.x = lastX;
						spaceItem.setLabel("|");
						addChild(spaceItem);
						
						lastX = spaceItem.x + spaceItem.width + space;
						//lastX = item.x + itemWidth;
					}
				}
				if (item.pageNum == _currentPageNum)
				{
					item.selected = true;
				}
				else
				{
					item.selected = false;
				}
				item.addEventListener("SelectPageItem", selectPageItem);
				addChild(item);
			}
		}
		
		public function set currentPageNum(num:uint):void
		{
			_currentPageNum = num;
			
			update();
		}
		
		public function get currentPageNum():uint
		{
			return _currentPageNum;
		}
		
		public function clear():void
		{
			while (this.numChildren)
			{
				this.removeChildAt(0);
			}
		}
		
		private function selectPageItem(evt:Event):void
		{
			var item:PageNavItem = evt.currentTarget as PageNavItem;
			currentPageNum = item.pageNum;
			
			dispatchEvent(new Event("SelectPage"));
		}
	}

}