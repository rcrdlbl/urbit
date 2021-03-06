import React, { Component } from 'react'
import { api } from '../../../api'

export class SidebarSwitcher extends Component {
  render() {

    let popoutSwitcher = this.props.popout
      ? "dn-m dn-l dn-xl"
      : "dib-m dib-l dib-xl";
    
    return (
      <div className="pt2">
        <a
          className="pointer flex-shrink-0"
          onClick={() => {
            api.sidebarToggle();
          }}>
          <img
            className={`pr3 dn ` + popoutSwitcher}
            src={
              this.props.sidebarShown
                ? "/~chat/img/ChatSwitcherLink.png"
                : "/~chat/img/ChatSwitcherClosed.png"
            }
            height="16"
            width="16"
          />
        </a>
      </div>
    );
  }
}

export default SidebarSwitcher
